ServerEvents.recipes(event => {
  // Cutting recipe for Dark Oak Log
  event.custom({
    type: 'farmersdelight:cutting',
    ingredients: [
      { item: 'minecraft:dark_oak_log' }
    ],
    tool: {
      type: 'farmersdelight:tool',
      item: 'hexalia:stone_dagger',
      damage: 1 // This makes the dagger lose 1 durability per use
    },
    result: [
      {
        item: 'hexalia:tree_resin',
        count: 1
      }
    ]
  });

  // Cutting recipe for Cottonwood Log
  event.custom({
    type: 'farmersdelight:cutting',
    ingredients: [
      { item: 'hexalia:cottonwood_log' }
    ],
    tool: {
      type: 'farmersdelight:tool',
      item: 'hexalia:stone_dagger',
      damage: 1
    },
    result: [
      {
        item: 'hexalia:tree_resin',
        count: 1
      }
    ]
  });
});
