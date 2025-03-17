from fastapi import FastAPI,File,UploadFile
from ocr import detect_text
from evaluation import evaluation_answer,evaluate_without_bert
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware




app=FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for testing
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods (GET, POST, etc.)
    allow_headers=["*"],  # Allow all headers
)

app.state.result=""
app.state.question=""
app.state.max_score=0
# Pydantic model to define the expected data structure
class TextRequest(BaseModel):
    question: str

class MaxScoreRequest(BaseModel):
    max_score: int


@app.get('/')
async def root():
    return {"name":"adersh","data":101}

@app.post("/max_score/")
async def receive_max_score(data: MaxScoreRequest):
    app.state.max_score=data.max_score
    return {"message": f"Received max score: {data.max_score}"}

@app.post('/question/')
async def receive_text(request: TextRequest):
    app.state.question=request.question
    print(f"question is {app.state.question}")
    return {"message": f"Received text: {request.question}"}
    


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
    
    score=evaluation_answer(app.state.question,app.state.result)
    return {"result":score}

@app.get("/testeval/")
async def eval_without_bert():
    image_path = "myfile.jpg"
    text = detect_text(image_path)
    app.state.result=','.join(text)
    app.state.result.replace("\n","")
    app.state.result.replace("\r","")
    print(app.state.result)
    
    out=evaluate_without_bert(app.state.question,app.state.result,app.state.max_score)
    print(f"output is {out}")
    return {"result":out}
