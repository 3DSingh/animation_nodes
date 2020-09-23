import bpy
import animation_nodes
from bpy.props import *
from ... events import treeChanged
from ... data_structures import ANStruct
from ... base_types import AnimationNode
from ... utils.nodes import newNodeAtCursor, invokeTranslation

class SimulationInputNode(bpy.types.Node, AnimationNode):
    bl_idname = "an_SimulationInputNode"
    bl_label = "Simulation Input"

    def inputNodeIdentifierChanged(self, context):
        treeChanged()

    simulationBlockIdentifier: StringProperty(update = inputNodeIdentifierChanged)
    sceneName: StringProperty(update = inputNodeIdentifierChanged)
    startFrame: IntProperty(update = inputNodeIdentifierChanged)
    endFrame: IntProperty(update = inputNodeIdentifierChanged)

    def create(self):
        self.newInput("Text", "Simulation Name", "simulationName", value = '', hide = True)
        self.newInput("Struct", "Initial Data", "dataInitial")
        self.newInput("Integer", "Start Frame", "startFrame", value = 1)
        self.newInput("Integer", "End Frame", "endFrame", value = 250)
        self.newInput("Scene", "Scene", "scene", hide = True)

        self.newOutput("Struct", "Data", "data")

    def draw(self, layout):
        if self.outputNode is None:
            self.invokeFunction(layout, "createSimulationOutputNode", text = "Output Node", icon = "PLUS")

    def execute(self, simulationName, dataInitial, startFrame, endFrame, scene):
        simulationBlockIdentifier = self.identifier + simulationName
        self.simulationBlockIdentifier = simulationBlockIdentifier
        self.sceneName = scene.name
        self.startFrame = startFrame
        self.endFrame = endFrame

        currentFrame = scene.frame_current
        if currentFrame < startFrame:
            setattr(animation_nodes, simulationBlockIdentifier, ANStruct())
        if currentFrame == startFrame:
            setattr(animation_nodes, simulationBlockIdentifier, dataInitial)
        if not hasattr(animation_nodes, simulationBlockIdentifier): return ANStruct()
        return getattr(animation_nodes, simulationBlockIdentifier)

    @property
    def outputNode(self):
        return self.network.getSimulationOutputNode(self.identifier)

    def createSimulationOutputNode(self):
        node = newNodeAtCursor("an_SimulationOutputNode")
        node.simulationInputIdentifier = self.identifier
        node.simulationBlockIdentifier = self.simulationBlockIdentifier
        node.sceneName = self.sceneName
        node.startFrame = self.startFrame
        node.endFrame = self.endFrame
        invokeTranslation()
