import Foundation

extension float4x4 {
    init(translation: SIMD3<Float>) {
        let matrix = float4x4(
            [            1,             0,             0, 0],
            [            0,             1,             0, 0],
            [            0,             0,             1, 0],
            [translation.x, translation.y, translation.z, 1]
        )
        self = matrix
    }

    init(scaling: SIMD3<Float>) {
        let matrix = float4x4(
            [scaling.x,         0,         0, 0],
            [        0, scaling.y,         0, 0],
            [        0,         0, scaling.z, 0],
            [        0,         0,         0, 1]
        )
        self = matrix
    }

    init(rotationX angle: Float) {
        let matrix = float4x4(
            [1,           0,          0, 0],
            [0,  cos(angle), sin(angle), 0],
            [0, -sin(angle), cos(angle), 0],
            [0,           0,          0, 1]
        )
        self = matrix
    }

    init(rotationY angle: Float) {
        let matrix = float4x4(
            [cos(angle), 0, -sin(angle), 0],
            [         0, 1,           0, 0],
            [sin(angle), 0,  cos(angle), 0],
            [         0, 0,           0, 1]
        )
        self = matrix
    }

    init(rotationZ angle: Float) {
        let matrix = float4x4(
            [ cos(angle), sin(angle), 0, 0],
            [-sin(angle), cos(angle), 0, 0],
            [          0,          0, 1, 0],
            [          0,          0, 0, 1]
        )
        self = matrix
    }

    init(rotation angle: SIMD3<Float>) {
        let rotationX = float4x4(rotationX: angle.x)
        let rotationY = float4x4(rotationY: angle.y)
        let rotationZ = float4x4(rotationZ: angle.z)
        self = rotationX * rotationY * rotationZ
    }

    init(projectionFov fov: Float, near: Float, far: Float, aspectRatio: Float, lhs: Bool = true) {
        let y = 1 / tan(fov * 0.5)
        let x = y / aspectRatio
        let z = lhs ? far / (far - near) : far / (near - far)
        let X = SIMD4<Float>( x,  0,  0,  0)
        let Y = SIMD4<Float>( 0,  y,  0,  0)
        let Z = lhs ? SIMD4<Float>( 0,  0,  z, 1) : SIMD4<Float>( 0,  0,  z, -1)
        let W = lhs ? SIMD4<Float>( 0,  0,  z * -near,  0) : SIMD4<Float>( 0,  0,  z * near,  0)
        self.init()
        columns = (X, Y, Z, W)
    }
}
