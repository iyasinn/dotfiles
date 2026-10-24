import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import artwork
import picker


class ArtworkTests(unittest.TestCase):
    def setUp(self):
        artwork.image_payload.cache_clear()
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.path = Path(self.directory.name) / "image.gif"
        self.bundled = Path(__file__).with_name("art") / "floating-island.gif"

    def test_missing_and_directory_are_optional(self):
        for path in (self.path, self.path.parent):
            self.assertIsNone(artwork.image_payload(str(path)))

    def test_unreadable_file_is_optional(self):
        self.path.write_bytes(self.bundled.read_bytes())
        with patch.object(Path, "open", side_effect=PermissionError):
            self.assertIsNone(artwork.image_payload(str(self.path)))

    def test_invalid_or_excessive_images_emit_nothing(self):
        data = self.bundled.read_bytes()
        samples = [b"not a gif", data[:-1], b"x" * (artwork.MAX_BYTES + 1),
                   data[:6] + b"\xff\xff\xff\xff" + data[10:]]
        for sample in samples:
            with self.subTest(size=len(sample)):
                artwork.image_payload.cache_clear()
                self.path.write_bytes(sample)
                stream = io.StringIO()
                with patch.object(picker, "ART_PATH", str(self.path)):
                    picker.render_art(stream=stream)
                self.assertEqual(stream.getvalue(), "")

    def test_bundled_image_is_cached_in_process(self):
        self.path.write_bytes(self.bundled.read_bytes())
        payload = artwork.image_payload(str(self.path))
        self.assertIsNotNone(payload)
        self.path.unlink()
        self.assertEqual(artwork.image_payload(str(self.path)), payload)

    def test_disabled_art_never_reads_file(self):
        with patch.object(picker, "ART_PATH", ""), patch.object(picker, "image_payload") as load:
            self.assertFalse(picker.artwork_available())
            picker.render_art(stream=io.StringIO())
            load.assert_not_called()

    def test_art_is_opt_in_and_not_an_fzf_preview(self):
        result = unittest.mock.Mock(returncode=0, stdout="selected\n")
        with patch.object(picker, "artwork_available", return_value=True), \
                patch.object(picker, "run_with_art_header", return_value=result) as header, \
                patch.object(picker.subprocess, "run", return_value=result) as run:
            picker.run_fzf("fzf", [], "row")
            header.assert_not_called()
            picker.run_fzf("fzf", [], "row", artwork=True)
            self.assertNotIn("--preview", header.call_args.args[1])
            self.assertEqual(run.call_count, 1)

    def test_resend_preserves_picker_state_and_rereads_source(self):
        directory = Path(self.directory.name)
        (directory / "sessions.json").write_text(json.dumps([]))
        rows = 'open\t"alpha"\talpha\nopen\t"beta"\tbeta\n'
        selected = rows.splitlines()[1]
        self.path.write_bytes(self.bundled.read_bytes())
        stream = io.StringIO()
        results = iter([["be", "ctrl-t", selected], ["be", "ctrl-p", selected], None])

        def screen(fzf, args, data, **kwargs):
            self.assertIn("--expect=enter,ctrl-r,ctrl-x,ctrl-t,ctrl-p", args)
            picker.render_art(stream=stream)
            return next(results)

        original_open = Path.open
        with patch.object(picker, "ART_PATH", str(self.path)), \
                patch.object(picker, "picker_size", return_value=(120, 36, 18, 0)), \
                patch.object(picker, "make_rows", return_value=rows), \
                patch.object(picker, "run_fzf", side_effect=screen) as run, \
                patch.object(picker, "request") as request, \
                patch.object(Path, "open", autospec=True, side_effect=original_open) as open_file:
            # Track source reads without interfering with sessions.json reads.
            picker.picker(directory, "fzf")
            image_reads = [call for call in open_file.call_args_list if call.args[0] == self.path]
            self.assertEqual(len(image_reads), 2)
            args = run.call_args.args[1]
            self.assertEqual(args[args.index("--query") + 1], "be")
            self.assertIn("--bind=start:pos(2)", args)
            self.assertIn("--preview-label= Session preview ", args)
            request.assert_called_once_with(directory, "cancel")
        self.assertEqual(stream.getvalue().count("\033]1337;File="), 3)


if __name__ == "__main__":
    unittest.main()
