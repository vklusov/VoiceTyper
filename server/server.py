#!/usr/bin/env python3
"""VoiceTyper Server — FastAPI backend for speech-to-text."""

import os
import sys
import time
import tempfile
import logging
from pathlib import Path

from fastapi import FastAPI, UploadFile, Form, File, HTTPException
from fastapi.responses import JSONResponse
import uvicorn

# ── Logging ──────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger("voicetyper")

# ── App ──────────────────────────────────────────────────
app = FastAPI(title="VoiceTyper Server", version="1.0.0")

# ── Global state (lazy init) ─────────────────────────────
whisper_model = None
ollama_client = None
current_whisper_model_name = "small"


def get_whisper():
    global whisper_model
    if whisper_model is None:
        log.info(f"Loading faster-whisper model: {current_whisper_model_name}...")
        from faster_whisper import WhisperModel
        t0 = time.time()
        whisper_model = WhisperModel(
            current_whisper_model_name,
            device="auto",
            compute_type="int8",
        )
        log.info(f"Model loaded in {time.time() - t0:.1f}s")
    return whisper_model


def get_ollama():
    global ollama_client
    if ollama_client is None:
        from ollama import Client
        ollama_client = Client(host="http://localhost:11434")
        # Warm-up check
        try:
            ollama_client.list()
        except Exception as e:
            log.warning(f"Ollama not reachable: {e}")
    return ollama_client


def clean_text_with_llm(text: str, language: str) -> str:
    """Pass raw transcript through LLM for punctuation/capitalization cleanup."""
    client = get_ollama()
    prompt = (
        f"Fix punctuation, capitalization, and formatting in the following text. "
        f"Keep all words exactly as they are. Do NOT change the meaning or wording. "
        f"Language: {language}.\n\nText: {text}"
    )
    try:
        response = client.chat(
            model="qwen2.5:3b",
            messages=[{"role": "user", "content": prompt}],
            options={"temperature": 0.0, "max_TOKEN_REMOVEDs": 512},
        )
        cleaned = response["message"]["content"].strip()
        return cleaned
    except Exception as e:
        log.warning(f"LLM cleanup failed: {e}")
        return text


# ── Routes ───────────────────────────────────────────────

@app.get("/status")
def status():
    """Health check endpoint."""
    ollama_ok = False
    try:
        get_ollama().list()
        ollama_ok = True
    except Exception:
        pass

    return {
        "status": "ok",
        "whisper_model": current_whisper_model_name,
        "whisper_loaded": whisper_model is not None,
        "ollama": "available" if ollama_ok else "unavailable",
    }


@app.get("/settings")
def get_settings():
    """Return current server settings."""
    return {
        "whisper_model": current_whisper_model_name,
        "available_models": ["tiny", "base", "small", "medium", "large-v3"],
    }


@app.post("/transcribe")
async def transcribe(
    audio: UploadFile = File(...),
    clean_llm: bool = Form(False),
    language: str = Form("auto"),
):
    """Transcribe audio file and optionally clean with LLM."""
    # Validate audio
    if not audio.filename:
        raise HTTPException(400, "No audio file provided")

    # Save uploaded file temporarily
    suffix = Path(audio.filename).suffix or ".wav"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        content = await audio.read()
        tmp.write(content)
        tmp_path = tmp.name

    try:
        model = get_whisper()

        # Transcribe
        log.info(f"Transcribing {audio.filename} ({len(content)} bytes, lang={language})...")
        t0 = time.time()

        seg_lang = language if language != "auto" else None
        segments, info = model.transcribe(
            tmp_path,
            language=seg_lang,
            beam_size=5,
            vad_filter=True,
        )

        segments = list(segments)
        duration_ms = int((time.time() - t0) * 1000)

        # Combine segments
        raw_transcript = " ".join(seg.text.strip() for seg in segments)
        detected_language = info.language

        log.info(
            f"Done in {duration_ms}ms | lang={detected_language} "
            f"| prob={info.language_probability:.2f} "
            f"| chars={len(raw_transcript)}"
        )

        # Optional LLM cleanup
        cleaned = None
        if clean_llm:
            log.info("Cleaning with LLM...")
            cleaned = clean_text_with_llm(raw_transcript, detected_language)

        return {
            "raw": raw_transcript,
            "cleaned": cleaned,
            "language": detected_language,
            "language_probability": info.language_probability,
            "duration_ms": duration_ms,
            "model": current_whisper_model_name,
        }

    except Exception as e:
        log.error(f"Transcription failed: {e}")
        raise HTTPException(500, f"Transcription failed: {e}")

    finally:
        # Cleanup temp file
        try:
            os.unlink(tmp_path)
        except Exception:
            pass


# ── Main ─────────────────────────────────────────────────
if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 9001
    log.info(f"Starting VoiceTyper server on port {port}")
    uvicorn.run(app, host="0.0.0.0", port=port, log_level="info")
