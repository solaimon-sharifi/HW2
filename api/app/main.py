from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from . import models, schemas, db as db_module

app = FastAPI(title="FastAPI + Postgres + pgAdmin Demo")


@app.on_event("startup")
def on_startup():
    # create tables
    models.Base.metadata.create_all(bind=db_module.engine)


@app.get('/health')
def health():
    return {"status": "ok"}


@app.post('/users/', response_model=schemas.User)
def create_user(user: schemas.UserCreate, db: Session = Depends(db_module.get_db)):
    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    new_user = models.User(username=user.username, email=user.email)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


@app.get('/users/', response_model=List[schemas.User])
def list_users(skip: int = 0, limit: int = 100, db: Session = Depends(db_module.get_db)):
    users = db.query(models.User).offset(skip).limit(limit).all()
    return users


@app.patch('/users/{user_id}', response_model=schemas.User)
def update_user(user_id: int, payload: schemas.UserUpdate, db: Session = Depends(db_module.get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if payload.username is not None:
        user.username = payload.username
    if payload.email is not None:
        user.email = payload.email
    db.commit()
    db.refresh(user)
    return user


@app.delete('/users/{user_id}')
def delete_user(user_id: int, db: Session = Depends(db_module.get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    db.delete(user)
    db.commit()
    return {"detail": "deleted"}


@app.post('/calculations/', response_model=schemas.Calculation)
def create_calculation(calc: schemas.CalculationCreate, db: Session = Depends(db_module.get_db)):
    user = db.query(models.User).filter(models.User.id == calc.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    db_calc = models.Calculation(
        operation=calc.operation,
        operand_a=calc.operand_a,
        operand_b=calc.operand_b,
        result=calc.result,
        user_id=calc.user_id,
    )
    db.add(db_calc)
    db.commit()
    db.refresh(db_calc)
    return db_calc


@app.get('/calculations/', response_model=List[schemas.Calculation])
def list_calculations(skip: int = 0, limit: int = 100, db: Session = Depends(db_module.get_db)):
    calculations = db.query(models.Calculation).offset(skip).limit(limit).all()
    return calculations


@app.get('/calculations/join')
def calculations_join(db: Session = Depends(db_module.get_db)):
    # Return joined user and calculation info
    rows = (
        db.query(models.User.username, models.Calculation.operation, models.Calculation.operand_a, models.Calculation.operand_b, models.Calculation.result)
        .join(models.Calculation, models.Calculation.user_id == models.User.id)
        .all()
    )
    return [
        {
            'username': r[0],
            'operation': r[1],
            'operand_a': r[2],
            'operand_b': r[3],
            'result': r[4],
        }
        for r in rows
    ]


@app.patch('/calculations/{calc_id}', response_model=schemas.Calculation)
def update_calculation(calc_id: int, payload: schemas.CalculationUpdate, db: Session = Depends(db_module.get_db)):
    calc = db.query(models.Calculation).filter(models.Calculation.id == calc_id).first()
    if not calc:
        raise HTTPException(status_code=404, detail="Calculation not found")
    calc.result = payload.result
    db.commit()
    db.refresh(calc)
    return calc


@app.delete('/calculations/{calc_id}')
def delete_calculation(calc_id: int, db: Session = Depends(db_module.get_db)):
    calc = db.query(models.Calculation).filter(models.Calculation.id == calc_id).first()
    if not calc:
        raise HTTPException(status_code=404, detail="Calculation not found")
    db.delete(calc)
    db.commit()
    return {"detail": "deleted"}
