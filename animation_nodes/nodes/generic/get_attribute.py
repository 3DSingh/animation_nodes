import bpy
from ... base_types import AnimationNode
from ... utils.names import getRandomString

class GetAttributeNode(bpy.types.Node, AnimationNode):
    bl_idname = "an_GetAttributeNode"
    bl_label = "Get Attribute"

    def create(self):
        self.newInput("Generic", "Data In", "dataIn")
        self.newInput("Integer", "Start Frame", "startFrame")
        self.newInput("Integer", "End Frame", "endFrame")
        self.newInput("Scene", "Scene", "scene", hide = True)

        self.newOutput("Text", "Attribute", "identifier")
        self.newOutput("Generic", "Data Out", "dataOut")
        self.newOutput("Generic", "Data Out", "dataOut0")

    def execute(self, dataIn, startFrame, endFrame, scene):
        identifier = self.identifier
        currentFrame = scene.frame_current
        if currentFrame == startFrame:
            setattr(bpy, identifier, dataIn)
        if not hasattr(bpy, identifier): return None, None, None
        return identifier, getattr(bpy, identifier), self
