import unittest
from unittest.mock import patch

from preview import preview_lines, safe_text


class PreviewTests(unittest.TestCase):
    session = {"name": "project", "status": "saved", "snapshot": {
        "window_states": [{"tabs": [{"title": "Editor", "pane_tree": {
            "cwd": "/project", "right": {"cwd": "/tests"}}}]}]}}

    def test_saved_session_shows_tabs_and_split_directories(self):
        with patch("preview.terminal_text") as live:
            text = "\n".join(preview_lines([self.session], "open", "project"))
        live.assert_not_called()
        for expected in ("Editor", "/project", "/tests", "fresh shells"):
            self.assertIn(expected, text)

    def test_running_session_uses_terminal_and_handles_closed_pane(self):
        session = dict(self.session, status="running")
        with patch("preview.terminal_text", return_value=["hello"]):
            self.assertIn("hello", preview_lines([session], "open", "project"))
        with patch("preview.terminal_text", return_value=None):
            self.assertIn("    └ /tests", preview_lines([session], "open", "project"))

    def test_create_and_missing_rows_do_not_read_terminals(self):
        with patch("preview.terminal_text") as live:
            self.assertIn("New session", preview_lines([], "create", "new"))
            self.assertEqual(preview_lines([], "open", "gone"), ["Session no longer available."])
        live.assert_not_called()

    def test_terminal_control_characters_are_not_forwarded(self):
        result = safe_text("hello\x1b]52;c;payload\x07\nworld\x9b")
        for control in ("\x1b", "\x07", "\x9b"):
            self.assertNotIn(control, result)
        self.assertIn("\nworld", result)
