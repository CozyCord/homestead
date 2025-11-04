ServerEvents.recipes(event => {
    event.remove({ output: 'minecraft:amethyst_shard', type: 'minecraft:stonecutting' })
    event.stonecutting('4x minecraft:amethyst_shard', 'minecraft:amethyst_block')
})