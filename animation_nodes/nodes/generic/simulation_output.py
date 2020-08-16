import bpy
import animation_nodes
from ... base_types import AnimationNode

class SimulationOutputNode(bpy.types.Node, AnimationNode):
    bl_idname = "an_SimulationOutputNode"
    bl_label = "Simulation Output"

    def create(self):
        self.newInput("Generic", "Sim Block", "simBlock")
        self.newInput("Struct", "Data", "data")

    def execute(self, simBlock, data):
        if simBlock is None or data is None: return
        identifier = simBlock[0]
        currentFrame = simBlock[1]
        startFrame = simBlock[2]
        endFrame = simBlock[3]
        if currentFrame >= startFrame and currentFrame <= endFrame:
            setattr(animation_nodes, identifier, data)
