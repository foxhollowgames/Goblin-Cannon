#!/usr/bin/env python3
"""
Ollama Local Code Generator for Goblin Cannon
Connects to local Ollama (http://localhost:11434) using Qwen 2.5 Coder (14B)
to generate, edit, and test Godot 4 GDScript code with zero API costs.
"""

import argparse
import json
import os
import sys
import urllib.request
import urllib.error

DEFAULT_OLLAMA_URL = os.environ.get("OLLAMA_HOST", "http://localhost:11434")
DEFAULT_MODEL = os.environ.get("OLLAMA_CODER_MODEL", "qwen2.5-coder:14b")

GODOT4_SYSTEM_PROMPT = """You are an expert Godot 4 and GDScript 2.0 developer for the Goblin Cannon game project.

Strict Rules:
1. Always write valid Godot 4 GDScript syntax.
2. Use modern annotations: @export, @onready. Never use deprecated Godot 3 export syntax.
3. Use typed variables, function signatures, and Callables.
4. Follow architecture conventions: Signal up, call down. Use integer energy units for gameplay calculations.
5. In static factory methods, avoid circular class_name references.
6. When writing unit tests, inherit from res://tests/test_base.gd and call assert_* methods.
7. Return only clean code without conversational filler.
"""

def check_ollama_status(base_url: str = DEFAULT_OLLAMA_URL) -> dict:
    """Check if Ollama server is running and return available models."""
    clean_url = base_url.rstrip("/")
    url = f"{clean_url}/api/tags"
    try:
        req = urllib.request.Request(url, method="GET")
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            return {"online": True, "models": [m["name"] for m in data.get("models", [])]}
    except Exception as e:
        return {"online": False, "error": str(e), "models": []}

def query_ollama(
    prompt: str,
    system_prompt: str = GODOT4_SYSTEM_PROMPT,
    model: str = DEFAULT_MODEL,
    base_url: str = DEFAULT_OLLAMA_URL,
    temperature: float = 0.2,
) -> str:
    """Send a generation request to Ollama and return the text response."""
    clean_url = base_url.rstrip("/")
    url = f"{clean_url}/api/generate"
    payload = {
        "model": model,
        "prompt": prompt,
        "system": system_prompt,
        "stream": False,
        "options": {
            "temperature": temperature,
        },
    }
    data_bytes = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data_bytes,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            res = json.loads(resp.read().decode("utf-8"))
            return res.get("response", "")
    except urllib.error.URLError as e:
        print(f"Error: Unable to connect to Ollama at {clean_url}. Is the Ollama server running?", file=sys.stderr)
        print(f"Details: {e}", file=sys.stderr)
        sys.exit(1)

def extract_code_block(text: str) -> str:
    """Extract code from markdown code fences if present."""
    lines = text.splitlines()
    inside_block = False
    extracted = []
    has_code_block = False

    for line in lines:
        if line.strip().startswith("```"):
            if not inside_block:
                inside_block = True
                has_code_block = True
                continue
            else:
                inside_block = False
                break
        if inside_block:
            extracted.append(line)

    if has_code_block:
        return "\n".join(extracted)
    return text.strip()

def cmd_status(args):
    status = check_ollama_status(args.url)
    if status["online"]:
        print(f"Ollama server is ONLINE at {args.url}")
        print("Available models:")
        for m in status["models"]:
            marker = " (Active default)" if m.startswith(args.model.split(":")[0]) else ""
            print(f"  - {m}{marker}")
    else:
        print(f"Ollama server is OFFLINE at {args.url}")
        print(f"Error: {status.get('error')}")
        sys.exit(1)

def cmd_generate(args):
    print(f"Querying {args.model} via Ollama...")
    prompt = args.prompt
    if args.context_file:
        if os.path.exists(args.context_file):
            with open(args.context_file, "r", encoding="utf-8") as f:
                context = f.read()
            prompt = f"Reference Context:\n```\n{context}\n```\n\nTask: {prompt}"
        else:
            print(f"Warning: Context file not found: {args.context_file}", file=sys.stderr)

    response = query_ollama(
        prompt=prompt,
        model=args.model,
        base_url=args.url,
        temperature=args.temperature,
    )

    code = extract_code_block(response) if args.strip_fences or args.output else response

    if args.output:
        os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(code + "\n")
        print(f"Successfully wrote {len(code.splitlines())} lines to {args.output}")
    else:
        print(code)

def cmd_edit(args):
    if not os.path.exists(args.file):
        print(f"Error: File not found: {args.file}", file=sys.stderr)
        sys.exit(1)

    with open(args.file, "r", encoding="utf-8") as f:
        existing_code = f.read()

    prompt = f"""Existing GDScript File ({args.file}):
```gdscript
{existing_code}
```

Instructions for edits:
{args.prompt}

Provide the complete updated file code."""

    print(f"Editing {args.file} using {args.model}...")
    response = query_ollama(
        prompt=prompt,
        model=args.model,
        base_url=args.url,
        temperature=args.temperature,
    )

    code = extract_code_block(response)
    out_file = args.output if args.output else args.file

    os.makedirs(os.path.dirname(os.path.abspath(out_file)), exist_ok=True)
    with open(out_file, "w", encoding="utf-8") as f:
        f.write(code + "\n")

    print(f"Successfully updated {out_file}")

def cmd_test(args):
    if not os.path.exists(args.file):
        print(f"Error: File not found: {args.file}", file=sys.stderr)
        sys.exit(1)

    with open(args.file, "r", encoding="utf-8") as f:
        source_code = f.read()

    suite_name = os.path.splitext(os.path.basename(args.file))[0].title().replace("_", "")

    prompt = f"""Write a comprehensive headless unit test for this GDScript file.
Source file ({args.file}):
```gdscript
{source_code}
```

Requirements for the test:
1. Inherit from 'res://tests/test_base.gd'.
2. Set suite_name = '{suite_name}'.
3. Implement func run() -> void that calls specific test functions.
4. Call begin('description') at the start of each test block.
5. Use assert_eq, assert_true, assert_false (use assert_eq(val, null) for null checks).
6. Make sure all created scene nodes are freed with .free() or .queue_free().
7. Return only the GDScript test code."""

    print(f"Generating unit test for {args.file} using {args.model}...")
    response = query_ollama(
        prompt=prompt,
        model=args.model,
        base_url=args.url,
        temperature=args.temperature,
    )

    code = extract_code_block(response)
    out_file = args.output if args.output else f"tests/test_{os.path.basename(args.file)}"

    os.makedirs(os.path.dirname(os.path.abspath(out_file)), exist_ok=True)
    with open(out_file, "w", encoding="utf-8") as f:
        f.write(code + "\n")

    print(f"Successfully created test file: {out_file}")

def main():
    parser = argparse.ArgumentParser(description="Ollama Local Code Generator for Goblin Cannon (Qwen 2.5 Coder 14B)")
    parser.add_argument("--url", default=DEFAULT_OLLAMA_URL, help=f"Ollama base URL (default: {DEFAULT_OLLAMA_URL})")
    parser.add_argument("--model", default=DEFAULT_MODEL, help=f"Model name (default: {DEFAULT_MODEL})")
    parser.add_argument("--temperature", type=float, default=0.2, help="Sampling temperature (default: 0.2)")

    subparsers = parser.add_subparsers(dest="command", required=True)

    # Status command
    p_status = subparsers.add_parser("status", help="Check local Ollama server status and models")
    p_status.set_defaults(func=cmd_status)

    # Generate command
    p_gen = subparsers.add_parser("generate", help="Generate GDScript from a prompt")
    p_gen.add_argument("--prompt", "-p", required=True, help="Instruction/prompt for code generation")
    p_gen.add_argument("--output", "-o", help="Path to write the generated code")
    p_gen.add_argument("--context-file", "-c", help="Optional context/reference file to include")
    p_gen.add_argument("--strip-fences", action="store_true", help="Strip markdown fences from stdout")
    p_gen.set_defaults(func=cmd_generate)

    # Edit command
    p_edit = subparsers.add_parser("edit", help="Edit an existing GDScript file with instructions")
    p_edit.add_argument("--file", "-f", required=True, help="Source file to edit")
    p_edit.add_argument("--prompt", "-p", required=True, help="Editing instructions")
    p_edit.add_argument("--output", "-o", help="Output file path (defaults to overwrite source file)")
    p_edit.set_defaults(func=cmd_edit)

    # Test command
    p_test = subparsers.add_parser("test", help="Generate unit tests for a GDScript file")
    p_test.add_argument("--file", "-f", required=True, help="Target GDScript file to write tests for")
    p_test.add_argument("--output", "-o", help="Output test file path (default: tests/test_<file>.gd)")
    p_test.set_defaults(func=cmd_test)

    args = parser.parse_args()
    args.func(args)

if __name__ == "__main__":
    main()
