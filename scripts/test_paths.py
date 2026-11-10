"""Ephemeral integration-test output lives outside the source tree by default."""
import os
from pathlib import Path
from tempfile import gettempdir

def artifact_path(*parts):
    root=Path(os.environ.get('RUGBY_TEST_ARTIFACTS',str(Path(gettempdir())/'rugby-test-results')))
    root.mkdir(parents=True,exist_ok=True)
    return root.joinpath(*parts)
