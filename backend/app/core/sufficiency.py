from enum import Enum


class Confidence(str, Enum):
    NONE   = "none"
    LOW    = "low"
    MEDIUM = "medium"
    HIGH   = "high"


# Threshold functions

def sleep_confidence(n_days: int) -> Confidence:
    if n_days >= 7: return Confidence.HIGH
    if n_days >= 5: return Confidence.MEDIUM
    if n_days >= 3: return Confidence.LOW
    return Confidence.NONE


def calorie_confidence(n_days: int) -> Confidence:
    if n_days >= 6: return Confidence.HIGH
    if n_days >= 5: return Confidence.MEDIUM
    if n_days >= 3: return Confidence.LOW
    return Confidence.NONE


def activity_confidence(n_sessions: int) -> Confidence:
    if n_sessions >= 4: return Confidence.MEDIUM
    if n_sessions >= 2: return Confidence.LOW
    return Confidence.NONE


def weight_confidence(n_entries: int, day_range: int) -> Confidence:
    if n_entries < 2:                     return Confidence.NONE
    if n_entries < 4 or day_range < 3:   return Confidence.LOW
    if n_entries < 10 or day_range < 14: return Confidence.MEDIUM
    return Confidence.HIGH


def relationship_confidence(n_paired_days: int) -> Confidence:
    if n_paired_days >= 21: return Confidence.HIGH
    if n_paired_days >= 14: return Confidence.MEDIUM
    if n_paired_days >= 7:  return Confidence.LOW
    return Confidence.NONE


def correlation_confidence(n: int) -> Confidence:
    if n >= 21: return Confidence.HIGH
    if n >= 10: return Confidence.MEDIUM
    return Confidence.NONE


def ttest_confidence(n: int) -> Confidence:
    if n >= 15: return Confidence.MEDIUM
    if n >= 7:  return Confidence.LOW
    return Confidence.NONE


# Recommendation gate

def can_recommend(
        confidence: Confidence,
        total_unique_days: int,
        is_relationship: bool = False,
) -> bool:
    if confidence == Confidence.NONE:               return False
    if total_unique_days < 5:                       return False
    if is_relationship and confidence == Confidence.LOW: return False
    return True


# Standard insufficient response

def insufficient(message: str, current: int = 0, needed: int = 0) -> dict:
    return {
        "status":  "insufficient",
        "message": message,
        "current": current,
        "needed":  needed,
    }
