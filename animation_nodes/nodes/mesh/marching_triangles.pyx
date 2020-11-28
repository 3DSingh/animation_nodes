import bpy
from bpy.props import *
from ... events import propertyChanged
from ... base_types import AnimationNode, VectorizedSocket
from ... data_structures.meshes.mesh_data import calculatePolygonNormals
from ... algorithms.mesh_generation.marching_triangles import marchingTrianglesOnMesh
from ... algorithms.mesh.triangulate_mesh import (
    triangulatePolygonsUsingFanSpanMethod,
    triangulatePolygonsUsingEarClipMethod
)
from ... data_structures cimport (
    Mesh,
    Falloff,
    Vector3DList,
    FalloffEvaluator,
    VirtualDoubleList,
    PolygonIndicesList,
)

class MarchingTrianglesNode(bpy.types.Node, AnimationNode):
    bl_idname = "an_MarchingTrianglesNode"
    bl_label = "Marching Triangles"
    errorHandlingType = "EXCEPTION"

    __annotations__ = {}
    __annotations__["clampFalloff"] = BoolProperty(name = "Clamp Falloff", default = False)
    __annotations__["useAdvancedTriangulationMethod"] = BoolProperty(name = "Use Ear Clip Triangulation Method",
                                                                     default = False, update = propertyChanged)
    __annotations__["useToleranceList"] = VectorizedSocket.newProperty()

    def create(self):
        self.newInput("Mesh", "Mesh", "mesh", dataIsModified = True)
        self.newInput("Falloff", "Falloff", "falloff")
        self.newInput(VectorizedSocket("Float", "useToleranceList",
            ("Threshold", "thresholds"), ("Thresholds", "thresholds")), value = 0.25)

        self.newOutput("Mesh", "Mesh", "mesh")
        self.newOutput("Vector List", "Normals", "normals", hide = True)

    def drawAdvanced(self, layout):
        layout.prop(self, "useAdvancedTriangulationMethod")

    def execute(self, mesh, Falloff falloff, thresholds):
        cdef Vector3DList vertices = mesh.vertices
        cdef PolygonIndicesList polygons = mesh.polygons

        if vertices.length == 0 or polygons.getLength() == 0:
            return Mesh(), Vector3DList()

        cdef VirtualDoubleList _thresholds = VirtualDoubleList.create(thresholds, 0)
        cdef long amountThreshold

        if not self.useToleranceList:
            amountThreshold = 1
        else:
            amountThreshold = _thresholds.getRealLength()

        if polygons.polyLengths.getMaxValue() > 3:
            if self.useAdvancedTriangulationMethod:
                polygons = triangulatePolygonsUsingEarClipMethod(vertices, polygons)
            else:
                polygons = triangulatePolygonsUsingFanSpanMethod(polygons)
        cdef Vector3DList polyNormals = calculatePolygonNormals(vertices, polygons)

        cdef FalloffEvaluator falloffEvaluator = self.getFalloffEvaluator(falloff)
        return marchingTrianglesOnMesh(vertices, polygons, polyNormals, falloffEvaluator,
                                       amountThreshold, _thresholds)

    def getFalloffEvaluator(self, falloff):
        try: return falloff.getEvaluator("LOCATION", self.clampFalloff)
        except: self.raiseErrorMessage("This falloff cannot be evaluated for vectors")
