import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import ollama_coder as coder


class GeneratorTests(unittest.TestCase):
    def test_fences_inside_source_are_preserved(self):
        source = 'text = """\n```\ninside\n```\n"""'
        self.assertEqual(coder.extract_code_block('```python\n' + source + '\n```'), source)
        self.assertEqual(coder.extract_code_block(source), source)
        with self.assertRaises(ValueError):
            coder.extract_code_block('```python\nincomplete')

    def test_prompt_file_and_language(self):
        with tempfile.TemporaryDirectory() as folder:
            prompt = Path(folder) / 'prompt.txt'
            output = Path(folder) / 'result.py'
            exact = 'Quotes " and backticks ` and $(literal)\nUnicode: café'
            prompt.write_text(exact, encoding='utf-8')
            args = ['coder', '--language', 'python', 'generate', '--prompt-file', str(prompt), '--output', str(output)]
            with patch.object(sys, 'argv', args), patch.object(coder, 'query_ollama', return_value='pass') as query, contextlib.redirect_stdout(io.StringIO()):
                coder.main()
            self.assertEqual(query.call_args.kwargs['prompt'], exact)
            self.assertEqual(query.call_args.kwargs['system_prompt'], coder.SYSTEM_PROMPTS['python'])
            self.assertEqual(output.read_text(), 'pass\n')
            with patch.object(sys, 'argv', args + ['--prompt', 'conflict']), contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
                coder.main()

    def test_rejected_response_preserves_existing_file(self):
        with tempfile.TemporaryDirectory() as folder:
            output = Path(folder) / 'result.py'
            output.write_text('original')
            args = ['coder', '--language', 'python', 'generate', '--prompt', 'test', '--output', str(output)]
            for response in [dict(done_reason='length', response='partial'),
                             dict(done_reason='stop', response='```python\nunclosed')]:
                with patch.object(sys, 'argv', args), patch.object(coder.urllib.request, 'urlopen') as request, contextlib.redirect_stdout(io.StringIO()):
                    request.return_value.__enter__.return_value.read.return_value = json.dumps(response).encode()
                    with self.assertRaises(ValueError):
                        coder.main()
                self.assertEqual(output.read_text(), 'original')


if __name__ == '__main__':
    unittest.main()
