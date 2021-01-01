import bpy
from bpy.props import *
from ... events import propertyChanged
from ... data_structures import ANStruct
from ... base_types import AnimationNode
from ... preferences import getColorSettings
from ... algorithms.random import getRandomColor
from ... utils.nodes import newNodeAtCursor, invokeTranslation

class SimulationInputNode(bpy.types.Node, AnimationNode):
    bl_idname = "an_SimulationInputNode"
    bl_label = "Simulation Input"

    simulationBlockID = 0
    simulationBlocks = {}
    simulationBlockFrames = {}
    simulationOutputIdentifier: StringProperty(update = propertyChanged)
    simulationBlockIdentifier: StringProperty(update = propertyChanged)
    sceneName: StringProperty(update = propertyChanged)
    startFrame: IntProperty(update = propertyChanged)
    endFrame: IntProperty(update = propertyChanged)

    def setup(self):
        self.use_custom_color = True
        self.useNetworkColor = False
        self.randomizeNetworkColor()

    def create(self):
        self.newInput("Struct", "Initial Data", "dataInitial", dataIsModified = True)
        self.newInput("Integer", "Start Frame", "startFrame", value = 1)
        self.newInput("Integer", "End Frame", "endFrame", value = 250)
        self.newInput("Scene", "Scene", "scene", hide = True)

        self.newOutput("Struct", "Data", "data")

    def draw(self, layout):
        if self.outputNode is None:
            self.invokeFunction(layout, "createSimulationOutputNode", text = "Output Node", icon = "PLUS")

    def execute(self, dataInitial, startFrame, endFrame, scene):
        self.simulationBlockID += 1
        simulationBlockIdentifier = self.identifier + str(self.simulationBlockID) + "_"
        self.simulationBlockIdentifier = simulationBlockIdentifier
        self.sceneName = scene.name
        self.startFrame = startFrame
        self.endFrame = endFrame

        currentFrame = scene.frame_current
        if currentFrame < startFrame:
            return ANStruct()
        if currentFrame == startFrame:
            self.resetSimulationBlock(simulationBlockIdentifier, startFrame, endFrame)
            self.simulationBlocks[simulationBlockIdentifier + str(currentFrame)] = dataInitial
            self.simulationBlockFrames[simulationBlockIdentifier + str(currentFrame)] = currentFrame

        return self.simulationBlocks.get(simulationBlockIdentifier + str(currentFrame), ANStruct())

    def resetSimulationBlock(self, simulationBlockIdentifier, start, end):
        for key in list(self.simulationBlocks.keys()):
            if key.startswith(simulationBlockIdentifier):
                self.simulationBlocks.pop(key, None)
                self.simulationBlockFrames.pop(key, None)

        for i in range(start, end + 1):
            self.simulationBlocks[simulationBlockIdentifier + str(i)] = ANStruct()
            self.simulationBlockFrames[simulationBlockIdentifier + str(i)] = None

    @property
    def outputNode(self):
        return self.network.getSimulationOutputNode(self.identifier)

    def createSimulationOutputNode(self):
        node = newNodeAtCursor("an_SimulationOutputNode")
        self.simulationOutputIdentifier = node.identifier
        node.simulationInputIdentifier = self.identifier
        node.use_custom_color = True
        node.useNetworkColor = False
        node.color = self.color
        invokeTranslation()

    def duplicate(self, sourceNode):
        self.randomizeNetworkColor()

    def randomizeNetworkColor(self):
        colors = getColorSettings()
        value = colors.subprogramValue
        saturation = colors.subprogramSaturation
        self.color = getRandomColor(value = value, saturation = saturation)
