from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm   # ← NUEVO
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from . import models, schemas, auth, database
 
models.Base.metadata.create_all(bind=database.engine)
 
app = FastAPI(title="SMAT API - Unidad I")
 
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:5000",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5000",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
 
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
 
# USUARIOS
 
@app.post("/usuarios/register", response_model=schemas.UsuarioResponse, tags=["Seguridad"])
def registrar_usuario(datos: schemas.UsuarioCreate, db: Session = Depends(database.get_db)):
    """Crea un nuevo usuario con contraseña encriptada."""
    existe = db.query(models.UsuarioDB).filter(models.UsuarioDB.email == datos.email).first()
    if existe:
        raise HTTPException(status_code=400, detail="El email ya está registrado")
 
    hash_password = pwd_context.hash(datos.password)
    nuevo = models.UsuarioDB(email=datos.email, password=hash_password)
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo
 
# ↓ CAMBIADO: ahora usa OAuth2PasswordRequestForm para compatibilidad con Swagger Y Flutter
@app.post("/token", response_model=schemas.TokenResponse, tags=["Seguridad"])
def login(
    datos: OAuth2PasswordRequestForm = Depends(),   # form data estándar
    db: Session = Depends(database.get_db)
):
    """Valida usuario y contraseña, devuelve un token JWT."""
    # OAuth2PasswordRequestForm usa 'username' — lo mapeamos a email
    usuario = db.query(models.UsuarioDB).filter(models.UsuarioDB.email == datos.username).first()
 
    if not usuario or not pwd_context.verify(datos.password, usuario.password):
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")
 
    token = auth.crear_token({"sub": usuario.email})
    return {"access_token": token, "token_type": "bearer"}
 
# ESTACIONES
@app.get("/estaciones/", response_model=list[schemas.Estacion], tags=["SMAT"])
def listar_estaciones(db: Session = Depends(database.get_db)):
    return db.query(models.EstacionDB).all()
 
@app.post("/estaciones/", tags=["SMAT"])
def crear_estacion(
    estacion: schemas.EstacionCreate,
    db: Session = Depends(database.get_db),
    user=Depends(auth.validar_token),
):
    nueva = models.EstacionDB(**estacion.dict())
    db.add(nueva)
    db.commit()
    return nueva
 
 
# ─────────────────────────────────────────────────────────────
# LECTURAS
# ─────────────────────────────────────────────────────────────
 
@app.post("/lecturas/", tags=["Telemetría"])
def registrar_lectura(
    lectura: schemas.LecturaCreate,
    db: Session = Depends(database.get_db),
    user=Depends(auth.validar_token),
):
    estacion = db.query(models.EstacionDB).filter(models.EstacionDB.id == lectura.estacion_id).first()
    if not estacion:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
 
    nueva_lectura = models.LecturaDB(**lectura.dict())
    db.add(nueva_lectura)
    db.commit()
    return {"status": "Lectura registrada con éxito"}