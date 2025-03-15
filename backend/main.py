from fastapi import FastAPI,File,UploadFile
from ocr import detect_text
from evaluation import evaluation_answer,evaluate_without_bert



app=FastAPI()

app.state.result=""

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
   app.state.result=','.join(text)
   app.state.result.replace("\n","")
   app.state.result.replace("\r","")
   return {'text':app.state.result}

@app.get("/evaluate/")
async def eval_answer():
    question="what is deep learning?"
    score=evaluation_answer(question,app.state.result)
    return {"result":score}

@app.get("/testeval/")
async def eval_without_bert():
    question="what is deep learning?"
    out=evaluate_without_bert(question,app.state.result,10)
    return {"output is":out}
