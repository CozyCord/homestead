StartupEvents.registry('item', event => {
    event.create('shiitake_mushroom_soup').food(food => {
        food
            .hunger(2)
            .saturation(2)
            .alwaysEdible
    })
    Platform.mods.kubejs.name = 'Homestead Addons'
})