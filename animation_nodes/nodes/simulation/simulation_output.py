import bpy
from bpy.props import *
from ... events import propertyChanged
from ... base_types import AnimationNode

class SimulationOutputNode(bpy.types.Node, AnimationNode):
    bl_idname = "an_SimulationOutputNode"
    bl_label = "Simulation Output"
    onlySearchTags = True

    simulationInputIdentifier: StringProperty(update = propertyChanged)

    def create(self):
        self.newInput("Struct", "Data", "data", dataIsModified = True)

    def execute(self, data):
        if data is None: return

        inputNode = self.inputNode()
        if inputNode is None: return
        self.setColor(inputNode)

        currentFrame = bpy.data.scenes[inputNode.sceneName].frame_current
        if currentFrame >= inputNode.startFrame and currentFrame <= inputNode.endFrame:
            simulationBlockIdentifier = inputNode.simulationBlockIdentifier + str(currentFrame + 1)
            if inputNode.simulationBlockFrames.get(simulationBlockIdentifier, None) is None:
                inputNode.simulationBlocks[simulationBlockIdentifier] = data
                inputNode.simulationBlockFrames[simulationBlockIdentifier] = currentFrame + 1

    def inputNode(self):
        return self.network.getSimulationInputNode(self.identifier)

    def setColor(self, inputNode):
        self.use_custom_color = inputNode.use_custom_color
        self.useNetworkColor = inputNode.useNetworkColor
        self.color = inputNode.color
