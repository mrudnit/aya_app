class FoodItem {
  final String name;
  final String category;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const FoodItem({
    required this.name,
    required this.category,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

const List<FoodItem> kFoodCatalog = [

  // VEGETABLES
  FoodItem(name: 'Tomato',        category: 'Vegetables', kcal: 18,  proteinG: 0.9, carbsG: 3.9,  fatG: 0.2),
  FoodItem(name: 'Cherry Tomato', category: 'Vegetables', kcal: 18,  proteinG: 0.9, carbsG: 3.9,  fatG: 0.2),
  FoodItem(name: 'Cucumber',      category: 'Vegetables', kcal: 15,  proteinG: 0.7, carbsG: 3.6,  fatG: 0.1),
  FoodItem(name: 'Carrot',        category: 'Vegetables', kcal: 41,  proteinG: 0.9, carbsG: 10.0, fatG: 0.2),
  FoodItem(name: 'Broccoli',      category: 'Vegetables', kcal: 34,  proteinG: 2.8, carbsG: 7.0,  fatG: 0.4),
  FoodItem(name: 'Spinach',       category: 'Vegetables', kcal: 23,  proteinG: 2.9, carbsG: 3.6,  fatG: 0.4),
  FoodItem(name: 'Bell Pepper',   category: 'Vegetables', kcal: 31,  proteinG: 1.0, carbsG: 6.0,  fatG: 0.3),
  FoodItem(name: 'Onion',         category: 'Vegetables', kcal: 40,  proteinG: 1.1, carbsG: 9.3,  fatG: 0.1),
  FoodItem(name: 'Garlic',        category: 'Vegetables', kcal: 149, proteinG: 6.4, carbsG: 33.0, fatG: 0.5),
  FoodItem(name: 'Potato',        category: 'Vegetables', kcal: 77,  proteinG: 2.0, carbsG: 17.0, fatG: 0.1),
  FoodItem(name: 'Sweet Potato',  category: 'Vegetables', kcal: 86,  proteinG: 1.6, carbsG: 20.0, fatG: 0.1),
  FoodItem(name: 'Zucchini',      category: 'Vegetables', kcal: 17,  proteinG: 1.2, carbsG: 3.1,  fatG: 0.3),
  FoodItem(name: 'Cabbage',       category: 'Vegetables', kcal: 25,  proteinG: 1.3, carbsG: 5.8,  fatG: 0.1),
  FoodItem(name: 'Cauliflower',   category: 'Vegetables', kcal: 25,  proteinG: 1.9, carbsG: 5.0,  fatG: 0.3),
  FoodItem(name: 'Lettuce',       category: 'Vegetables', kcal: 15,  proteinG: 1.4, carbsG: 2.9,  fatG: 0.2),
  FoodItem(name: 'Mushroom',      category: 'Vegetables', kcal: 22,  proteinG: 3.1, carbsG: 3.3,  fatG: 0.3),
  FoodItem(name: 'Eggplant',      category: 'Vegetables', kcal: 25,  proteinG: 1.0, carbsG: 6.0,  fatG: 0.2),
  FoodItem(name: 'Corn',          category: 'Vegetables', kcal: 96,  proteinG: 3.4, carbsG: 21.0, fatG: 1.5),
  FoodItem(name: 'Peas',          category: 'Vegetables', kcal: 81,  proteinG: 5.4, carbsG: 14.5, fatG: 0.4),
  FoodItem(name: 'Beetroot',      category: 'Vegetables', kcal: 43,  proteinG: 1.6, carbsG: 10.0, fatG: 0.2),
  FoodItem(name: 'Celery',        category: 'Vegetables', kcal: 16,  proteinG: 0.7, carbsG: 3.0,  fatG: 0.2),
  FoodItem(name: 'Asparagus',     category: 'Vegetables', kcal: 20,  proteinG: 2.2, carbsG: 3.9,  fatG: 0.1),
  FoodItem(name: 'Pumpkin',       category: 'Vegetables', kcal: 26,  proteinG: 1.0, carbsG: 6.5,  fatG: 0.1),
  FoodItem(name: 'Avocado',       category: 'Vegetables', kcal: 160, proteinG: 2.0, carbsG: 9.0,  fatG: 15.0),
  FoodItem(name: 'Green Beans',   category: 'Vegetables', kcal: 31,  proteinG: 1.8, carbsG: 7.0,  fatG: 0.1),

  // FRUITS
  FoodItem(name: 'Apple',         category: 'Fruits', kcal: 52,  proteinG: 0.3, carbsG: 14.0, fatG: 0.2),
  FoodItem(name: 'Banana',        category: 'Fruits', kcal: 89,  proteinG: 1.1, carbsG: 23.0, fatG: 0.3),
  FoodItem(name: 'Orange',        category: 'Fruits', kcal: 47,  proteinG: 0.9, carbsG: 12.0, fatG: 0.1),
  FoodItem(name: 'Strawberry',    category: 'Fruits', kcal: 32,  proteinG: 0.7, carbsG: 7.7,  fatG: 0.3),
  FoodItem(name: 'Grape',         category: 'Fruits', kcal: 69,  proteinG: 0.7, carbsG: 18.0, fatG: 0.2),
  FoodItem(name: 'Watermelon',    category: 'Fruits', kcal: 30,  proteinG: 0.6, carbsG: 7.6,  fatG: 0.2),
  FoodItem(name: 'Mango',         category: 'Fruits', kcal: 60,  proteinG: 0.8, carbsG: 15.0, fatG: 0.4),
  FoodItem(name: 'Pineapple',     category: 'Fruits', kcal: 50,  proteinG: 0.5, carbsG: 13.0, fatG: 0.1),
  FoodItem(name: 'Pear',          category: 'Fruits', kcal: 57,  proteinG: 0.4, carbsG: 15.0, fatG: 0.1),
  FoodItem(name: 'Peach',         category: 'Fruits', kcal: 39,  proteinG: 0.9, carbsG: 10.0, fatG: 0.3),
  FoodItem(name: 'Blueberry',     category: 'Fruits', kcal: 57,  proteinG: 0.7, carbsG: 14.5, fatG: 0.3),
  FoodItem(name: 'Raspberry',     category: 'Fruits', kcal: 52,  proteinG: 1.2, carbsG: 12.0, fatG: 0.7),
  FoodItem(name: 'Kiwi',          category: 'Fruits', kcal: 61,  proteinG: 1.1, carbsG: 15.0, fatG: 0.5),
  FoodItem(name: 'Lemon',         category: 'Fruits', kcal: 29,  proteinG: 1.1, carbsG: 9.3,  fatG: 0.3),
  FoodItem(name: 'Cherry',        category: 'Fruits', kcal: 63,  proteinG: 1.1, carbsG: 16.0, fatG: 0.2),
  FoodItem(name: 'Plum',          category: 'Fruits', kcal: 46,  proteinG: 0.7, carbsG: 11.0, fatG: 0.3),
  FoodItem(name: 'Pomegranate',   category: 'Fruits', kcal: 83,  proteinG: 1.7, carbsG: 19.0, fatG: 1.2),
  FoodItem(name: 'Melon',         category: 'Fruits', kcal: 34,  proteinG: 0.8, carbsG: 8.2,  fatG: 0.2),

  // MEAT & FISH
  FoodItem(name: 'Chicken Breast',   category: 'Meat & Fish', kcal: 165, proteinG: 31.0, carbsG: 0.0,  fatG: 3.6),
  FoodItem(name: 'Chicken Thigh',    category: 'Meat & Fish', kcal: 209, proteinG: 26.0, carbsG: 0.0,  fatG: 11.0),
  FoodItem(name: 'Chicken Wings',    category: 'Meat & Fish', kcal: 203, proteinG: 30.0, carbsG: 0.0,  fatG: 8.1),
  FoodItem(name: 'Ground Beef (lean)',category: 'Meat & Fish',kcal: 215, proteinG: 26.0, carbsG: 0.0,  fatG: 12.0),
  FoodItem(name: 'Ground Beef (fat)', category: 'Meat & Fish',kcal: 332, proteinG: 14.0, carbsG: 0.0,  fatG: 30.0),
  FoodItem(name: 'Beef Steak',       category: 'Meat & Fish', kcal: 271, proteinG: 26.0, carbsG: 0.0,  fatG: 18.0),
  FoodItem(name: 'Pork Chop',        category: 'Meat & Fish', kcal: 231, proteinG: 25.0, carbsG: 0.0,  fatG: 14.0),
  FoodItem(name: 'Bacon',            category: 'Meat & Fish', kcal: 541, proteinG: 37.0, carbsG: 1.4,  fatG: 42.0),
  FoodItem(name: 'Ham',              category: 'Meat & Fish', kcal: 145, proteinG: 21.0, carbsG: 1.5,  fatG: 5.5),
  FoodItem(name: 'Turkey Breast',    category: 'Meat & Fish', kcal: 135, proteinG: 30.0, carbsG: 0.0,  fatG: 1.0),
  FoodItem(name: 'Lamb Chop',        category: 'Meat & Fish', kcal: 294, proteinG: 25.0, carbsG: 0.0,  fatG: 21.0),
  FoodItem(name: 'Salmon',           category: 'Meat & Fish', kcal: 208, proteinG: 20.0, carbsG: 0.0,  fatG: 13.0),
  FoodItem(name: 'Tuna (canned)',    category: 'Meat & Fish', kcal: 116, proteinG: 26.0, carbsG: 0.0,  fatG: 1.0),
  FoodItem(name: 'Cod',              category: 'Meat & Fish', kcal: 82,  proteinG: 18.0, carbsG: 0.0,  fatG: 0.7),
  FoodItem(name: 'Shrimp',           category: 'Meat & Fish', kcal: 99,  proteinG: 24.0, carbsG: 0.2,  fatG: 0.3),
  FoodItem(name: 'Mackerel',         category: 'Meat & Fish', kcal: 205, proteinG: 19.0, carbsG: 0.0,  fatG: 14.0),
  FoodItem(name: 'Herring',          category: 'Meat & Fish', kcal: 158, proteinG: 18.0, carbsG: 0.0,  fatG: 9.0),
  FoodItem(name: 'Egg (whole)',      category: 'Meat & Fish', kcal: 155, proteinG: 13.0, carbsG: 1.1,  fatG: 11.0),
  FoodItem(name: 'Egg White',        category: 'Meat & Fish', kcal: 52,  proteinG: 11.0, carbsG: 0.7,  fatG: 0.2),

  // DAIRY
  FoodItem(name: 'Whole Milk',      category: 'Dairy', kcal: 61,  proteinG: 3.2, carbsG: 4.8,  fatG: 3.3),
  FoodItem(name: 'Skimmed Milk',    category: 'Dairy', kcal: 35,  proteinG: 3.4, carbsG: 5.0,  fatG: 0.1),
  FoodItem(name: 'Greek Yogurt',    category: 'Dairy', kcal: 97,  proteinG: 9.0, carbsG: 3.6,  fatG: 5.0),
  FoodItem(name: 'Plain Yogurt',    category: 'Dairy', kcal: 61,  proteinG: 3.5, carbsG: 4.7,  fatG: 3.3),
  FoodItem(name: 'Cheddar Cheese',  category: 'Dairy', kcal: 402, proteinG: 25.0,carbsG: 1.3,  fatG: 33.0),
  FoodItem(name: 'Mozzarella',      category: 'Dairy', kcal: 280, proteinG: 28.0,carbsG: 3.1,  fatG: 17.0),
  FoodItem(name: 'Cottage Cheese',  category: 'Dairy', kcal: 98,  proteinG: 11.0,carbsG: 3.4,  fatG: 4.3),
  FoodItem(name: 'Butter',          category: 'Dairy', kcal: 717, proteinG: 0.9, carbsG: 0.1,  fatG: 81.0),
  FoodItem(name: 'Cream Cheese',    category: 'Dairy', kcal: 342, proteinG: 6.2, carbsG: 4.1,  fatG: 34.0),
  FoodItem(name: 'Sour Cream',      category: 'Dairy', kcal: 193, proteinG: 2.1, carbsG: 4.6,  fatG: 19.0),
  FoodItem(name: 'Kefir',           category: 'Dairy', kcal: 52,  proteinG: 3.3, carbsG: 4.8,  fatG: 2.0),
  FoodItem(name: 'Parmesan',        category: 'Dairy', kcal: 431, proteinG: 38.0,carbsG: 4.1,  fatG: 29.0),
  FoodItem(name: 'Feta',            category: 'Dairy', kcal: 264, proteinG: 14.0,carbsG: 4.1,  fatG: 21.0),
  FoodItem(name: 'Gouda',           category: 'Dairy', kcal: 356, proteinG: 25.0,carbsG: 2.2,  fatG: 28.0),

  // GRAINS & CARBS
  FoodItem(name: 'White Rice',       category: 'Grains', kcal: 130, proteinG: 2.7, carbsG: 28.0, fatG: 0.3),
  FoodItem(name: 'Brown Rice',       category: 'Grains', kcal: 112, proteinG: 2.6, carbsG: 24.0, fatG: 0.9),
  FoodItem(name: 'Oats',             category: 'Grains', kcal: 389, proteinG: 17.0,carbsG: 66.0, fatG: 7.0),
  FoodItem(name: 'White Bread',      category: 'Grains', kcal: 265, proteinG: 9.0, carbsG: 51.0, fatG: 3.2),
  FoodItem(name: 'Whole Wheat Bread',category: 'Grains', kcal: 247, proteinG: 13.0,carbsG: 41.0, fatG: 3.4),
  FoodItem(name: 'Pasta',            category: 'Grains', kcal: 131, proteinG: 5.0, carbsG: 25.0, fatG: 1.1),
  FoodItem(name: 'Buckwheat',        category: 'Grains', kcal: 155, proteinG: 6.0, carbsG: 33.0, fatG: 1.0),
  FoodItem(name: 'Quinoa',           category: 'Grains', kcal: 120, proteinG: 4.4, carbsG: 22.0, fatG: 1.9),
  FoodItem(name: 'Lentils',          category: 'Grains', kcal: 116, proteinG: 9.0, carbsG: 20.0, fatG: 0.4),
  FoodItem(name: 'Chickpeas',        category: 'Grains', kcal: 164, proteinG: 8.9, carbsG: 27.0, fatG: 2.6),
  FoodItem(name: 'Black Beans',      category: 'Grains', kcal: 132, proteinG: 8.9, carbsG: 24.0, fatG: 0.5),
  FoodItem(name: 'Tortilla',         category: 'Grains', kcal: 312, proteinG: 7.5, carbsG: 51.0, fatG: 7.3),
  FoodItem(name: 'Rye Bread',        category: 'Grains', kcal: 259, proteinG: 8.5, carbsG: 48.0, fatG: 3.3),
  FoodItem(name: 'Cornflakes',       category: 'Grains', kcal: 357, proteinG: 7.5, carbsG: 84.0, fatG: 0.9),

  // EXTRAS
  FoodItem(name: 'Olive Oil',        category: 'Extras', kcal: 884, proteinG: 0.0, carbsG: 0.0,  fatG: 100.0),
  FoodItem(name: 'Sunflower Oil',    category: 'Extras', kcal: 884, proteinG: 0.0, carbsG: 0.0,  fatG: 100.0),
  FoodItem(name: 'Peanut Butter',    category: 'Extras', kcal: 588, proteinG: 25.0,carbsG: 20.0, fatG: 50.0),
  FoodItem(name: 'Honey',            category: 'Extras', kcal: 304, proteinG: 0.3, carbsG: 82.0, fatG: 0.0),
  FoodItem(name: 'Dark Chocolate',   category: 'Extras', kcal: 546, proteinG: 5.0, carbsG: 60.0, fatG: 31.0),
  FoodItem(name: 'Almonds',          category: 'Extras', kcal: 579, proteinG: 21.0,carbsG: 22.0, fatG: 50.0),
  FoodItem(name: 'Walnuts',          category: 'Extras', kcal: 654, proteinG: 15.0,carbsG: 14.0, fatG: 65.0),
  FoodItem(name: 'Cashews',          category: 'Extras', kcal: 553, proteinG: 18.0,carbsG: 30.0, fatG: 44.0),
  FoodItem(name: 'Peanuts',          category: 'Extras', kcal: 567, proteinG: 26.0,carbsG: 16.0, fatG: 49.0),
  FoodItem(name: 'Whey Protein',     category: 'Extras', kcal: 352, proteinG: 80.0,carbsG: 5.0,  fatG: 3.5),
  FoodItem(name: 'Tofu',             category: 'Extras', kcal: 76,  proteinG: 8.0, carbsG: 1.9,  fatG: 4.8),
  FoodItem(name: 'Hummus',           category: 'Extras', kcal: 166, proteinG: 7.9, carbsG: 14.0, fatG: 10.0),
  FoodItem(name: 'Mayonnaise',       category: 'Extras', kcal: 680, proteinG: 1.0, carbsG: 0.6,  fatG: 75.0),
  FoodItem(name: 'Sugar',            category: 'Extras', kcal: 387, proteinG: 0.0, carbsG: 100.0,fatG: 0.0),
];

final List<String> kFoodCategories = kFoodCatalog
    .map((f) => f.category)
    .toSet()
    .toList();

// Meal types
const List<String> kMealTypes = [
  'breakfast',
  'lunch',
  'dinner',
  'snack',
];
