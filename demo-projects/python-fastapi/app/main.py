from fastapi import FastAPI

app = FastAPI(title="Code Haven Demo API", version="1.0.0")


@app.get("/")
async def root():
    return {"message": "Hello from Code Haven demo!", "status": "running"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


@app.get("/add/{a}/{b}")
async def add(a: int, b: int):
    return {"result": a + b}


@app.get("/multiply/{a}/{b}")
async def multiply(a: int, b: int):
    return {"result": a * b}
