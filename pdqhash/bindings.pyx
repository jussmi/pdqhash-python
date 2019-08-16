# distutils: language = c++
import numpy as np
cimport numpy as np

cdef extern from "../ThreatExchange/hashing/pdq/cpp/common/pdqhashtypes.cpp" namespace "facebook::pdq::hashing":
    cdef struct Hash256:
        unsigned short w[16]
        

cdef extern from "../ThreatExchange/hashing/pdq/cpp/hashing/pdqhashing.cpp" namespace "facebook::pdq::hashing":
    void pdqHash256FromFloatLuma(
        float* fullBuffer1,
        float* fullBuffer2,
        int numRows,
        int numCols,
        float buffer64x64[64][64],
        float buffer16x64[16][64],
        float buffer16x16[16][16],
        Hash256& hash_value,
        int& quality
    )

cdef extern from "../ThreatExchange/hashing/pdq/cpp/downscaling/downscaling.cpp" namespace "facebook::pdq::downscaling":
    int computeJaroszFilterWindowSize(int oldDimension, int newDimension)

cdef extern from "../ThreatExchange/hashing/pdq/cpp/hashing/torben.cpp" namespace "facebook::pdq::hashing":
    float torben(float m[], int n)

def compute(np.ndarray[char, ndim=3] image) -> int:
    cdef np.ndarray[float, ndim=2] gray = (image[:, :, 0]*0.299 + image[:, :, 1]*0.587 + image[:, :, 2] * 0.114).astype('float32')
    cdef np.ndarray[float, ndim=2] placeholder = np.zeros_like(gray)
    cdef Hash256 hash_value = Hash256()
    cdef int quality = 0
    cdef int numRows = gray.shape[0]
    cdef int numCols = gray.shape[1]
    cdef float buffer64x64[64][64]
    cdef float buffer16x64[16][64]
    cdef float buffer16x16[16][16]
    cdef float* fullBuffer1 = &gray[0, 0]
    cdef float* fullBuffer2 = &placeholder[0, 0]
    result = pdqHash256FromFloatLuma(
        fullBuffer1,
        fullBuffer2,
        numRows,
        numCols,
        buffer64x64,
        buffer16x64,
        buffer16x16,
        hash_value,
        quality
    )
    return np.array([(hash_value.w[(k & 255) >> 4] >> (k & 15)) & 1 for k in range(256)]).reshape(16, 16)[:, ::-1].flatten()