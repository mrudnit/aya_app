// Muscle groups
const List<String> kMuscleGroups = [
  'chest',
  'back',
  'legs',
  'shoulders',
  'arms',
  'full_body',
  'other',
];

const Map<String, String> kMuscleGroupLabels = {
  'chest':     'Chest',
  'back':      'Back',
  'legs':      'Legs',
  'shoulders': 'Shoulders',
  'arms':      'Arms',
  'full_body': 'Full Body',
  'other':     'Other',
};

// Exercises for muscle group
const Map<String, List<String>> kExercisesByGroup = {
  'chest': [
    'Bench Press',
    'Incline Bench Press',
    'Dumbbell Press',
    'Cable Fly',
    'Other',
  ],
  'back': [
    'Barbell Row',
    'Pull Up',
    'Lat Pulldown',
    'Cable Row',
    'Other',
  ],
  'legs': [
    'Squat',
    'Leg Press',
    'Romanian Deadlift',
    'Leg Extension',
    'Leg Curl',
    'Other',
  ],
  'shoulders': [
    'Overhead Press',
    'Lateral Raise',
    'Front Raise',
    'Face Pull',
    'Other',
  ],
  'arms': [
    'Barbell Curl',
    'Dumbbell Curl',
    'Triceps Pushdown',
    'Skull Crusher',
    'Other',
  ],
  'full_body': [
    'Deadlift',
    'Clean and Press',
    'Burpees',
    'Other',
  ],
  'other': [
    'Other',
  ],
};

// Cardio types
const List<String> kCardioTypes = [
  'walking',
  'running',
  'cycling',
  'swimming',
  'other',
];

const Map<String, String> kCardioTypeLabels = {
  'walking':  'Walking',
  'running':  'Running',
  'cycling':  'Cycling',
  'swimming': 'Swimming',
  'other':    'Other',
};
