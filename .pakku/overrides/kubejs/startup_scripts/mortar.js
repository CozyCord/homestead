ItemEvents.modification(event => {
  event.modify('expandeddelight:mortar_and_pestle_item', item => {
    item.maxDamage = 64;
  });
});