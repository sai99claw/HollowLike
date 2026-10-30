"""Boundary checks use sparse files; no export assets or player saves are changed."""
import contextlib
import importlib.util
import io
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('budget', Path(__file__).resolve().parents[1]/'scripts/release_budget.py')
budget = importlib.util.module_from_spec(spec)
spec.loader.exec_module(budget)


class ReleaseBudgetTests(unittest.TestCase):
    def test_file_limit_rejects_before_transfer(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp)/'game-0.bin'
            with path.open('wb') as file:
                file.truncate(budget.FILE_LIMIT)
            with self.assertRaisesRegex(ValueError, '16 MiB'):
                budget.validate_budget(Path(temp))

    def test_total_limit_includes_worker_files(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for index in range(19):
                with (root/f'game-{index}.bin').open('wb') as file:
                    file.truncate(14*1024*1024)
            with self.assertRaisesRegex(ValueError, 'Previous build preserved'):
                budget.validate_budget(root)

    def test_small_candidate_counts_extra_worker(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            candidate = root/'candidate';candidate.mkdir()
            (candidate/'index.html').write_bytes(b'123')
            worker = root/'worker.js';worker.write_bytes(b'12')
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(budget.validate_budget(candidate, [worker]), 5)


if __name__ == '__main__':
    unittest.main()
