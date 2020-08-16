import bpy
from ... base_types import AnimationNode

class SetAttributeNode(bpy.types.Node, AnimationNode):
    bl_idname = "an_SetAttributeNode"
    bl_label = "Set Attribute"

    def create(self):
        self.newInput("Text", "Attribute", "identifier")
        self.newInput("Generic", "Data In", "dataIn")

    def execute(self, identifier, dataIn):
        if identifier is None or dataIn is None: return
        setattr(bpy, identifier, dataIn)
