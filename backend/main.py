from fastapi import FastAPI,File,UploadFile
from ocr import detect_text


app=FastAPI()

@app.get('/')
async def root():
    return {"name":"adersh","data":101}


@app.post("/upload/")
async def create_upload(file:UploadFile=File(...)):
    file.filename="myfile.jpg"
    contents=await file.read()

    with open(f"images/{file.filename}","wb") as f:
        f.write(contents)
    return {"filename":file.filename}

@app.get("/convert/")
async def convert_text():
   image_path = "myfile.jpg"
   text = detect_text(image_path)
   return {'text':text}

    