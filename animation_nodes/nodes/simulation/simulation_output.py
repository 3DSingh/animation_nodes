import bpy
import animation_nodes
from bpy.props import *
from ... events import treeChanged
from ... base_types import AnimationNode

class SimulationOutputNode(bpy.types.Node, AnimationNode):
    bl_idname = "an_SimulationOutputNode"
    bl_label = "Simulation Output"
    onlySearchTags = True

    def inputNodeIdentifierChanged(self, context):
        treeChanged()

    simulationInputIdentifier: StringProperty(update = inputNodeIdentifierChanged)
    simulationBlockIdentifier: StringProperty(update = inputNodeIdentifierChanged)
    sceneName: StringProperty(update = inputNodeIdentifierChanged)
    startFrame: IntProperty(update = inputNodeIdentifierChanged)
    endFrame: IntProperty(update = inputNodeIdentifierChanged)

    def create(self):
        self.newInput("Struct", "Data", "data")

    def execute(self, data):
        if data is None: return
        currentFrame = bpy.data.scenes[self.sceneName].frame_current
        if currentFrame >= self.startFrame and currentFrame <= self.endFrame:
            setattr(animation_nodes, self.simulationBlockIdentifier, data)
