import os
import json
import asyncio
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict

try:
    from app.services.ai_service import DashScopeClient
except ImportError:
    # Fallback to local import if structure is different
    from services.ai_service import DashScopeClient

router = APIRouter()

class TranslateRequest(BaseModel):
    strings: List[str]

class TranslateResponse(BaseModel):
    translations: Dict[str, Dict[str, str]]

@router.post("/i18n_proxy", response_model=TranslateResponse)
async def i18n_proxy(request: TranslateRequest):
    """
    Temporary internal proxy for batch translating Flutter UI literal strings
    using the backend's DashScope credentials.
    Returns:
    {
      "translations": {
        "原中文": {"en": "English", "zh_TW": "繁体中文"},
        ...
      }
    }
    """
    if not request.strings:
        return TranslateResponse(translations={})

    ai_client = DashScopeClient()
    
    # We will construct a bulk prompt to save requests.
    prompt = "You are a professional Flutter UI translator. Please translate the following Chinese UI texts into strictly English and Traditional Chinese. "
    prompt += "Return the result strictly as a valid JSON object where the key is the exact original Chinese snippet, and the value is another JSON object with 'en' and 'zh_TW' keys containing the translations. Do not return any other text or markdown block markers.\n\n"
    prompt += "Example format:\n{\"原中文\": {\"en\": \"English Text\", \"zh_TW\": \"繁體中文\"}}\n\nTexts to translate:\n"
    
    for s in request.strings:
        prompt += f'- "{s}"\n'

    try:
        response = await ai_client.generate_text(prompt)
        
        # Clean up possible markdown code blocks
        if response.startswith("```json"):
            response = response[7:]
        if response.startswith("```"):
            response = response[3:]
        if response.endswith("```"):
            response = response[:-3]
            
        result_json = json.loads(response.strip())
        return TranslateResponse(translations=result_json)
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
