import sys
import json
import os
import requests
import base64

def image_to_base64(image_path):
    with open(image_path, "rb") as img_file:
        return base64.b64encode(img_file.read()).decode("utf-8")

def call_openai_api(file_path, api_key):
    try:
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}"
        }
        content = []
        if file_path.endswith((".png", ".jpg", ".jpeg", ".bmp")):
            base64_image = image_to_base64(file_path)
            content.append({
                "type": "image_url",
                "image_url": {"url": f"data:image/png;base64,{base64_image}"}
            })
        elif file_path.endswith((".wav", ".ogg", ".mp3")):
            # Note: GPT-4o doesn't process audio directly; use placeholder text
            content.append({
                "type": "text",
                "text": f"Audio file named {os.path.basename(file_path)}"
            })
        
        content.insert(0, {
            "type": "text",
            "text": "Analyze this file and suggest a character name (e.g., Player, Enemy, NPC). Return JSON with 'character_name'."
        })
        
        payload = {
            "model": "gpt-4o",
            "messages": [{"role": "user", "content": content}]
        }
        response = requests.post("https://api.openai.com/v1/chat/completions", headers=headers, json=payload)
        response.raise_for_status()
        result = response.json()
        content = result["choices"][0]["message"]["content"]
        try:
            return json.loads(content)
        except json.JSONDecodeError:
            start = content.find("{")
            end = content.rfind("}") + 1
            if start != -1 and end != -1:
                return json.loads(content[start:end])
            return {"error": "Invalid API response"}
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No file path provided"}))
        sys.exit(1)
    file_path = sys.argv[1]
    api_key = os.environ.get("OPENAI_API_KEY", "")
    if not api_key:
        print(json.dumps({"error": "No API key provided"}))
        sys.exit(1)
    
    result = call_openai_api(file_path, api_key)
    print(json.dumps(result, indent=2))