class_name TileMapFinder extends RefCounted

func find_tilemap_nodes(root: Node) -> Array[TileMapLayer]:
    var tilemaps: Array[TileMapLayer] = []
    for child in root.get_children():
        if is_tilemap_node(child):
            tilemaps.append(child)
        tilemaps.append_array(find_tilemap_nodes(child)) # Recursive search
    return tilemaps

func is_tilemap_node(node: Node) -> bool:
    return node is TileMapLayer and node.tile_set != null
