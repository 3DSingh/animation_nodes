import cython
from ... math cimport Vector3
from cpython.mem cimport PyMem_Malloc, PyMem_Free
from ... data_structures cimport (
    Mesh,
    LongList,
    FloatList,
    Vector3DList,
    EdgeIndicesList,
    FalloffEvaluator,
    VirtualDoubleList,
    PolygonIndicesList,
)


cdef struct Vertex:
    Vector3 location

cdef struct VertexList:
    Py_ssize_t vertexAmount
    Vertex *data


cdef struct Edge:
    Py_ssize_t start
    Py_ssize_t end

cdef struct EdgeList:
    Py_ssize_t edgeAmount
    Edge *data


cdef struct EdgePrevious:
    Py_ssize_t start
    Py_ssize_t end
    Py_ssize_t vertexIndex

cdef struct EdgePreviousList:
    Py_ssize_t edgePreviousAmount
    EdgePrevious *data

def marchingTrianglesOnMesh(Vector3DList points, PolygonIndicesList polygons,
                            FalloffEvaluator falloffEvaluator, long amountThreshold,
                            VirtualDoubleList thresholds):

    cdef long polyAmount = polygons.getLength()

    # Initialization of vertices of contour.
    cdef Vertex* vertices
    cdef VertexList vertexList

    vertexList.vertexAmount = 0
    vertexList.data = <Vertex*>PyMem_Malloc(2 * polyAmount * sizeof(Vertex))
    vertices = vertexList.data

    # Initialization of edges contour.
    cdef Edge* edges
    cdef EdgeList edgeList

    edgeList.edgeAmount = 0
    edgeList.data = <Edge*>PyMem_Malloc(polyAmount * sizeof(Edge))
    edges = edgeList.data

    # Initialization of edgesPrevious.
    cdef EdgePrevious* edgesPrevious
    cdef EdgePreviousList edgePreviousList

    edgePreviousList.edgePreviousAmount = 0
    edgePreviousList.data = <EdgePrevious*>PyMem_Malloc(2 * polyAmount * sizeof(EdgePrevious))
    edgesPrevious = edgePreviousList.data

    cdef Py_ssize_t i
    for i in range(2 * polyAmount):
        edgesPrevious[i].start = -1
        edgesPrevious[i].end = -1

    cdef FloatList strengths = falloffEvaluator.evaluateList(points)
    cdef unsigned int *polyStarts = polygons.polyStarts.data
    cdef unsigned int *indices = polygons.indices.data
    cdef Py_ssize_t a, b, c, start

    for i in range(polyAmount):
        start = polyStarts[i]
        a = indices[start]
        b = indices[start + 1]
        c = indices[start + 2]
        for j in range(amountThreshold):
            marchingTriangle(points, strengths, <float>thresholds.get(j), a,
                             b, c, &vertexList, &edgeList, &edgePreviousList)

    cdef Py_ssize_t vertexAmount = vertexList.vertexAmount
    cdef Vector3DList verticesOut = Vector3DList(length = vertexAmount)
    for i in range(vertexAmount):
        verticesOut.data[i] = vertices[i].location

    cdef Py_ssize_t edgeAmount = edgeList.edgeAmount
    cdef EdgeIndicesList edgesOut = EdgeIndicesList(length = edgeAmount)
    for i in range(edgeAmount):
       edgesOut.data[i].v1 = edges[i].start
       edgesOut.data[i].v2 = edges[i].end

    cdef PolygonIndicesList polygonsOut = PolygonIndicesList()

    PyMem_Free(vertices)
    PyMem_Free(edges)
    PyMem_Free(edgesPrevious)
    return Mesh(verticesOut, edgesOut, polygonsOut)

cdef void marchingTriangle(Vector3DList points, FloatList strengths, float tolerance,
                           Py_ssize_t a, Py_ssize_t b, Py_ssize_t c, VertexList* vertexList,
                           EdgeList* edgeList, EdgePreviousList* edgePreviousList):
    '''
    Indices order for an triangle.
            a
           ' '
          '   '
         '     '
        d-------b
    '''
    cdef long indexTriangle = binaryToDecimal(a, b, c, strengths, tolerance)
    if indexTriangle == 0 or indexTriangle == 7:
        return
    elif indexTriangle == 1:
        calculateContourSegment(c, a, c, b, points, strengths, tolerance, vertexList,
                                edgeList, edgePreviousList)
    elif indexTriangle == 2:
        calculateContourSegment(b, c, b, a, points, strengths, tolerance, vertexList,
                                edgeList, edgePreviousList)
    elif indexTriangle == 3:
        calculateContourSegment(b, a, c, a, points, strengths, tolerance, vertexList,
                                edgeList, edgePreviousList)
    elif indexTriangle == 4:
        calculateContourSegment(a, b, a, c, points, strengths, tolerance, vertexList,
                                edgeList, edgePreviousList)
    elif indexTriangle == 5:
        calculateContourSegment(a, b, c, b, points, strengths, tolerance, vertexList,
                                edgeList, edgePreviousList)
    elif indexTriangle == 6:
        calculateContourSegment(a, c, b, c, points, strengths, tolerance, vertexList,
                                edgeList, edgePreviousList)


cdef long binaryToDecimal(Py_ssize_t a, Py_ssize_t b, Py_ssize_t c, FloatList strengths,
                          float t):
    cdef float sa, sb, sc
    sa, sb, sc = strengths.data[a], strengths.data[b], strengths.data[c]

    # Binary order (sc, sb, sa).
    if sa <= t: sa = 0
    else: sa = 1

    if sb <= t: sb = 0
    else: sb = 1

    if sc <= t: sc = 0
    else: sc = 1

    return <long>(4.0 * sa + 2.0 * sb + sc)


cdef void calculateContourSegment(Py_ssize_t a, Py_ssize_t b, Py_ssize_t c, Py_ssize_t d,
                                  Vector3DList points, FloatList strengths, float tolerance,
                                  VertexList* vertexList, EdgeList* edgeList,
                                  EdgePreviousList* edgePreviousList):
    cdef Py_ssize_t edgeAmount = edgeList[0].edgeAmount
    cdef Edge* edges = edgeList[0].data

    edges[edgeAmount].start = calculateVertexUpdateEdgePreviousList(a, b, points, strengths,
                                                                    tolerance, vertexList,
                                                                    edgePreviousList)
    edges[edgeAmount].end = calculateVertexUpdateEdgePreviousList(c, d, points, strengths,
                                                                  tolerance, vertexList,
                                                                  edgePreviousList)
    edgeList[0].edgeAmount += 1


cdef Py_ssize_t calculateVertexUpdateEdgePreviousList(Py_ssize_t a, Py_ssize_t b,
                                                      Vector3DList points, FloatList strengths,
                                                      float tolerance, VertexList* vertexList,
                                                      EdgePreviousList* edgePreviousList):
    cdef Py_ssize_t vertexAmount = vertexList[0].vertexAmount
    cdef Vertex* vertices = vertexList[0].data

    cdef Py_ssize_t edgePreviousAmount = edgePreviousList[0].edgePreviousAmount
    cdef EdgePrevious* edgesPrevious = edgePreviousList[0].data
    cdef Py_ssize_t i, start, end, vertexIndex

    vertexIndex = -1
    for i in range(edgePreviousAmount):
        start = edgesPrevious[i].start
        end = edgesPrevious[i].end
        if a == start and b == end:
            vertexIndex = edgesPrevious[i].vertexIndex
            break
        elif a == end and b == start:
            vertexIndex = edgesPrevious[i].vertexIndex
            break

    cdef Vector3 v
    if vertexIndex == -1:
        lerpVec3(&v, points.data + a, points.data + b, strengths.data[a], strengths.data[b],
                 tolerance)
        vertexIndex = vertexAmount
        vertices[vertexAmount].location = v
        vertexList[0].vertexAmount += 1

    edgesPrevious[edgePreviousAmount].vertexIndex = vertexIndex
    edgesPrevious[edgePreviousAmount].start = a
    edgesPrevious[edgePreviousAmount].end = b
    edgePreviousList[0].edgePreviousAmount += 1

    return vertexIndex


cdef void lerpVec3(Vector3* target, Vector3* va, Vector3* vb, float a, float b, float tolerance):
    target.x = lerp(va.x, vb.x, a, b, tolerance)
    target.y = lerp(va.y, vb.y, a, b, tolerance)
    target.z = lerp(va.z, vb.z, a, b, tolerance)


@cython.cdivision(True)
cdef float lerp(float t1, float t2, float f1, float f2, float tolerance):
    return t1 + (tolerance - f1) * (t2 - t1) / (f2 - f1)
