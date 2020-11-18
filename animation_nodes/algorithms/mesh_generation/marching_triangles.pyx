import cython
from ... utils.limits cimport INT_MAX
from ... math cimport Vector3, toVector3
from ... data_structures cimport (
    Mesh,
    FloatList,
    Vector3DList,
    EdgeIndicesList,
    FalloffEvaluator,
    VirtualDoubleList,
    PolygonIndicesList,
)

def marchingTrianglesOnMesh(Vector3DList points, PolygonIndicesList polygons,
                            FalloffEvaluator falloffEvaluator, long amountThreshold,
                            VirtualDoubleList thresholds):

    cdef FloatList strengths = falloffEvaluator.evaluateList(points)

    cdef unsigned int *polyStarts = polygons.polyStarts.data
    cdef unsigned int *indices = polygons.indices.data
    cdef Py_ssize_t i, a, b, c, start

    meshes = []
    for i in range(polygons.getLength()):
        start = polyStarts[i]
        a = indices[start]
        b = indices[start + 1]
        c = indices[start + 2]
        for j in range(amountThreshold):
            meshes.append(getMeshOfTriangle(points, strengths, <float>thresholds.get(j),
                                            a, b, c))
    return Mesh.join(*meshes)

def getMeshOfTriangle(Vector3DList points, FloatList strengths, float tolerance,
                      Py_ssize_t a, Py_ssize_t b, Py_ssize_t c):
    '''
    Indices order for an triangle.
            a
           ' '
          '   '
         '     '
        d-------b
    '''
    cdef long indexTriangle = binaryToDecimal(a, b, c, strengths, tolerance)
    if indexTriangle == 0:
        return Mesh()
    elif indexTriangle == 1:
        return getMesh(c, a, c, b, points, strengths, tolerance)
    elif indexTriangle == 2:
        return getMesh(b, c, b, a, points, strengths, tolerance)
    elif indexTriangle == 3:
        return getMesh(b, a, c, a, points, strengths, tolerance)
    elif indexTriangle == 4:
        return getMesh(a, b, a, c, points, strengths, tolerance)
    elif indexTriangle == 5:
        return getMesh(a, b, c, b, points, strengths, tolerance)
    elif indexTriangle == 6:
        return getMesh(a, c, b, c, points, strengths, tolerance)
    elif indexTriangle == 7:
        return Mesh()

cdef long binaryToDecimal(Py_ssize_t a, Py_ssize_t b, Py_ssize_t c, FloatList strengths, float t):
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

cdef Mesh getMesh(Py_ssize_t a, Py_ssize_t b, Py_ssize_t c, Py_ssize_t d,
                  Vector3DList points, FloatList strengths, float tolerance):
    cdef Vector3DList vertices = Vector3DList(length = 2)
    cdef EdgeIndicesList edges = EdgeIndicesList(length = 1)
    cdef PolygonIndicesList polygons = PolygonIndicesList()

    edges.data[0].v1 = 0
    edges.data[0].v2 = 1

    lerpVec3(vertices.data + 0, points.data + a, points.data + b, strengths.data[a],
             strengths.data[b], tolerance)
    lerpVec3(vertices.data + 1, points.data + c, points.data + d, strengths.data[c],
             strengths.data[d], tolerance)
    return Mesh(vertices, edges, polygons)

cdef void lerpVec3(Vector3* target, Vector3* va, Vector3* vb, float a, float b, float tolerance):
    target.x = lerp(va.x, vb.x, a, b, tolerance)
    target.y = lerp(va.y, vb.y, a, b, tolerance)
    target.z = lerp(va.z, vb.z, a, b, tolerance)

@cython.cdivision(True)
cdef float lerp(float t1, float t2, float f1, float f2, float tolerance):
    return t1 + (tolerance - f1) * (t2 - t1) / (f2 - f1)
