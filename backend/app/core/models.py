from ..core.db import Base
from sqlalchemy import Column, BigInteger, String, Integer, Numeric, ForeignKey, DateTime, Text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

# ─────────────────────────────────────────────────────────────
# EXERCISE
# ─────────────────────────────────────────────────────────────

class Workout(Base):
    __tablename__ = "workouts"

    id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    workout_type = Column(Text)
    title = Column(String(100))
    duration_min = Column(Integer)
    performed_at = Column(DateTime(timezone=True), server_default=func.now())
    calories_burned = Column(Numeric(10, 2))
    health_score = Column(Integer)
    notes = Column(Text)
    
    exercises = relationship("WorkoutExercise", back_populates="workout", cascade="all, delete")

class WorkoutExercise(Base):
    __tablename__ = "workout_exercises"

    id = Column(BigInteger, primary_key=True, index=True)
    workout_id = Column(BigInteger, ForeignKey("workouts.id", ondelete="CASCADE"), nullable=False)
    exercise_name = Column(String(100), nullable=False)
    sets = Column(Integer)
    reps = Column(Integer)
    weight_kg = Column(Numeric(8, 2))
    
    workout = relationship("Workout", back_populates="exercises")