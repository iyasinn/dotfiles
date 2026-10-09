import json
import shutil
import unittest

from picker import make_rows, valid_name


@unittest.skipUnless(shutil.which("fzf"), "fzf is required")
class PickerTests(unittest.TestCase):
    sessions = [{"name": "dotfiles", "status": "active"}, {"name": "website", "status": "saved"}]

    def rows(self, query, sessions=None):
        return [row.split("\t", 2) for row in make_rows(
            self.sessions if sessions is None else sessions, query, shutil.which("fzf")
        ).splitlines()]

    def test_fuzzy_match_keeps_explicit_create_choice(self):
        rows = self.rows("dtf")
        self.assertEqual([r[0] for r in rows], ["open", "create"])
        self.assertEqual(json.loads(rows[0][1]), "dotfiles")
        self.assertEqual(json.loads(rows[1][1]), "dtf")

    def test_exact_name_has_no_duplicate_create(self):
        self.assertEqual([r[0] for r in self.rows("dotfiles")], ["open"])

    def test_unmatched_name_can_be_created(self):
        rows = self.rows("new project")
        self.assertEqual(rows[0][0], "create")
        self.assertEqual(json.loads(rows[0][1]), "new project")

    def test_shell_punctuation_remains_literal(self):
        name = "a 'quoted' $(name); / path"
        self.assertEqual(json.loads(self.rows(name, [])[0][1]), name)

    def test_empty_query_never_creates_empty_session(self):
        self.assertEqual(self.rows("", [])[0][0], "hint")

    def test_invalid_names(self):
        for name in ("", "  ", "bad\nname", "bad\tname", "x" * 121):
            with self.subTest(name=name), self.assertRaises(ValueError):
                valid_name(name)
        self.assertEqual(valid_name("  my session  "), "my session")


if __name__ == "__main__":
    unittest.main()
