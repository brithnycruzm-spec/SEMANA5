from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

# ── Usuarios ──────────────────────────────────────────────
class UsuarioCreate(BaseModel):
    email: str
    password: str

class UsuarioResponse(BaseModel):
    id: int
    email: str

    class Config:
        from_attributes = True

class LoginRequest(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str

# ── Estaciones ────────────────────────────────────────────
class EstacionBase(BaseModel):
    nombre: str
    ubicacion: str

class EstacionCreate(EstacionBase):
    pass

class Estacion(EstacionBase):
    id: int

    class Config:
        from_attributes = True

# ── Lecturas ──────────────────────────────────────────────
class LecturaBase(BaseModel):
    valor: float
    estacion_id: int

class LecturaCreate(LecturaBase):
    fecha: Optional[datetime] = None

class Lectura(LecturaBase):
    id: int
    fecha: datetime

    class Config:
        from_attributes = True