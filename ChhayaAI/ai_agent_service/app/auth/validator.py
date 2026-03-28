"""
Transport-level auth checks only. Replace TODO with real JWT / JWKS verification.
"""
from __future__ import annotations

import os


def auth_required() -> bool:
    return os.getenv("AUTH_REQUIRED", "").strip().lower() in ("1", "true", "yes")


def validate_authorization(authorization: str | None) -> tuple[bool, str | None]:
    """
    Returns (ok, error_message). When AUTH_REQUIRED is false, always ok.
    """
    if not auth_required():
        return True, None
    if not authorization or not isinstance(authorization, str):
        return False, "Missing Authorization header"
    auth = authorization.strip()
    if not auth.lower().startswith("bearer "):
        return False, "Authorization must be Bearer token"
    token = auth[7:].strip()
    if not token:
        return False, "Empty bearer token"
    # TODO: verify JWT signature, exp, aud
    return True, None
