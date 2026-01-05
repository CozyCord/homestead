ServerEvents.recipes(event => {
  // Define pestles that will lose durability instead of being consumed
  const pestles = [
    'hexalia:mortar_and_pestle',
    'expandeddelight:mortar_and_pestle_item'
  ];

  // Add a shapeless recipe for each pestle that damages the pestle
  pestles.forEach(pestle => {
    event.shapeless(
      Item.of('create:wheat_flour', 4),           // Recipe result
      [pestle, '#forge:grains/wheats']            // Inputs
    )
    .damageIngredient(pestle)                     // Damages the pestle by 1
    .id(`homestead:wheat_flour_with_${pestle.replace(':', '_')}`); // Unique ID
  });
});