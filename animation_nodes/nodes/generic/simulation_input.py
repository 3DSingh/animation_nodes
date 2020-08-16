import bpy
import animation_nodes
from ... data_structures import ANStruct
from ... base_types import AnimationNode

class SimulationInputNode(bpy.types.Node, AnimationNode):
    bl_idname = "an_SimulationInputNode"
    bl_label = "Simulation Input"

    def create(self):
        self.newInput("Text", "Simulation Name", "simulationName", value = '', hide = True)
        self.newInput("Struct", "Data Initial", "dataInitial")
        self.newInput("Integer", "Start Frame", "startFrame", value = 1)
        self.newInput("Integer", "End Frame", "endFrame", value = 250)
        self.newInput("Scene", "Scene", "scene", hide = True)

        self.newOutput("Generic", "Sim Block", "simBlock")
        self.newOutput("Struct", "Data", "data")

    def execute(self, simulationName, dataInitial, startFrame, endFrame, scene):
        identifier = self.identifier + simulationName
        currentFrame = scene.frame_current
        if currentFrame < startFrame:
            setattr(animation_nodes, identifier, ANStruct())
        if currentFrame == startFrame:
            setattr(animation_nodes, identifier, dataInitial)
        if not hasattr(animation_nodes, identifier): return None, ANStruct()
        simBlock = [identifier, currentFrame, startFrame, endFrame]
        return simBlock, getattr(animation_nodes, identifier)
