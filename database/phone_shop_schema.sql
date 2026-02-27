-- ============================================================================
-- BASE DE DATOS: phone_shop
-- Descripcion: Sistema de gestion para negocio de venta de productos de
--              tecnologia (celulares y repuestos) y servicio tecnico
--              tercerizado de celulares.
-- Motor: MySQL 8.0+
-- ============================================================================

CREATE DATABASE IF NOT EXISTS phone_shop
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE phone_shop;

-- ============================================================================
-- 1. TABLAS DE ENTIDADES PRINCIPALES
-- ============================================================================

-- Clientes del negocio
CREATE TABLE clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    documento VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    direccion VARCHAR(255),
    email VARCHAR(100),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Proveedores de productos
CREATE TABLE proveedores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    nit VARCHAR(20) UNIQUE,
    telefono VARCHAR(20),
    direccion VARCHAR(255),
    email VARCHAR(100),
    contacto VARCHAR(100),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Centros especializados de reparacion (servicio tercerizado)
CREATE TABLE centros_servicio (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    direccion VARCHAR(255),
    contacto VARCHAR(100),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Categorias de productos (celulares, pantallas, baterias, etc.)
CREATE TABLE categorias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255)
) ENGINE=InnoDB;

-- Catalogo de productos (celulares y repuestos)
CREATE TABLE productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    categoria_id INT,
    precio_compra DECIMAL(12,2) NOT NULL,
    precio_venta DECIMAL(12,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_productos_categoria FOREIGN KEY (categoria_id)
        REFERENCES categorias(id) ON UPDATE CASCADE ON DELETE SET NULL,
    INDEX idx_productos_nombre (nombre)
) ENGINE=InnoDB;

-- Cuentas bancarias del negocio (para registrar pagos por transferencia)
CREATE TABLE cuentas_bancarias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    banco VARCHAR(100) NOT NULL,
    numero_cuenta VARCHAR(30) NOT NULL,
    tipo_cuenta ENUM('ahorro', 'corriente') NOT NULL,
    titular VARCHAR(100) NOT NULL,
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================================
-- 2. TABLAS DE COMPRAS (adquisicion de productos a proveedores)
-- ============================================================================

-- Facturas de compra a proveedores
CREATE TABLE compras (
    id INT AUTO_INCREMENT PRIMARY KEY,
    proveedor_id INT NOT NULL,
    fecha DATE NOT NULL,
    tipo_pago ENUM('contado', 'credito') NOT NULL,
    metodo_pago ENUM('efectivo', 'transferencia'),
    cuenta_bancaria_id INT,
    referencia_pago VARCHAR(100),
    total DECIMAL(12,2) NOT NULL,
    observaciones TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_compras_proveedor FOREIGN KEY (proveedor_id)
        REFERENCES proveedores(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_compras_cuenta FOREIGN KEY (cuenta_bancaria_id)
        REFERENCES cuentas_bancarias(id) ON UPDATE CASCADE ON DELETE SET NULL,
    INDEX idx_compras_fecha (fecha)
) ENGINE=InnoDB;

-- Detalle de cada factura de compra (productos adquiridos)
CREATE TABLE detalle_compras (
    id INT AUTO_INCREMENT PRIMARY KEY,
    compra_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(12,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_det_compras_compra FOREIGN KEY (compra_id)
        REFERENCES compras(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_det_compras_producto FOREIGN KEY (producto_id)
        REFERENCES productos(id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================================
-- 3. TABLAS DE VENTAS (venta de productos a clientes)
-- ============================================================================

-- Facturas de venta a clientes
CREATE TABLE ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    fecha DATE NOT NULL,
    tipo_pago ENUM('contado', 'credito') NOT NULL,
    metodo_pago ENUM('efectivo', 'transferencia'),
    cuenta_bancaria_id INT,
    referencia_pago VARCHAR(100),
    total DECIMAL(12,2) NOT NULL,
    observaciones TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ventas_cliente FOREIGN KEY (cliente_id)
        REFERENCES clientes(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ventas_cuenta FOREIGN KEY (cuenta_bancaria_id)
        REFERENCES cuentas_bancarias(id) ON UPDATE CASCADE ON DELETE SET NULL,
    INDEX idx_ventas_fecha (fecha)
) ENGINE=InnoDB;

-- Detalle de cada factura de venta (productos vendidos)
CREATE TABLE detalle_ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    venta_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(12,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_det_ventas_venta FOREIGN KEY (venta_id)
        REFERENCES ventas(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_det_ventas_producto FOREIGN KEY (producto_id)
        REFERENCES productos(id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================================
-- 4. TABLAS DE SERVICIO TECNICO (reparacion tercerizada)
-- ============================================================================

-- Ordenes de servicio tecnico
CREATE TABLE ordenes_servicio (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    centro_servicio_id INT NOT NULL,
    fecha_recepcion DATE NOT NULL,
    fecha_entrega_estimada DATE,
    fecha_entrega_real DATE,
    marca_equipo VARCHAR(50),
    modelo_equipo VARCHAR(50),
    imei VARCHAR(20),
    descripcion_problema TEXT NOT NULL,
    diagnostico TEXT,
    descripcion_solucion TEXT,
    costo_servicio_centro DECIMAL(12,2),
    precio_cliente DECIMAL(12,2),
    tipo_pago ENUM('contado', 'credito') NOT NULL,
    metodo_pago ENUM('efectivo', 'transferencia'),
    cuenta_bancaria_id INT,
    referencia_pago VARCHAR(100),
    estado ENUM('recibido', 'enviado_centro', 'en_reparacion',
                'reparado', 'entregado', 'cancelado') NOT NULL DEFAULT 'recibido',
    observaciones TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_ordenes_cliente FOREIGN KEY (cliente_id)
        REFERENCES clientes(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ordenes_centro FOREIGN KEY (centro_servicio_id)
        REFERENCES centros_servicio(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_ordenes_cuenta FOREIGN KEY (cuenta_bancaria_id)
        REFERENCES cuentas_bancarias(id) ON UPDATE CASCADE ON DELETE SET NULL,
    INDEX idx_ordenes_fecha_recepcion (fecha_recepcion),
    INDEX idx_ordenes_estado (estado)
) ENGINE=InnoDB;

-- Insumos utilizados en cada orden de servicio
CREATE TABLE insumos_orden_servicio (
    id INT AUTO_INCREMENT PRIMARY KEY,
    orden_servicio_id INT NOT NULL,
    producto_id INT,
    descripcion VARCHAR(200),
    cantidad INT NOT NULL,
    costo_unitario DECIMAL(12,2) NOT NULL,
    subtotal_costo DECIMAL(12,2) NOT NULL,
    origen ENUM('propio', 'centro') NOT NULL,
    CONSTRAINT fk_insumos_orden FOREIGN KEY (orden_servicio_id)
        REFERENCES ordenes_servicio(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_insumos_producto FOREIGN KEY (producto_id)
        REFERENCES productos(id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================================
-- 5. TABLAS DE ABONOS (pagos a deuda total)
-- ============================================================================

-- Abonos de clientes a su deuda total
CREATE TABLE abonos_clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    fecha DATE NOT NULL,
    monto DECIMAL(12,2) NOT NULL,
    metodo_pago ENUM('efectivo', 'transferencia') NOT NULL,
    cuenta_bancaria_id INT,
    referencia VARCHAR(100),
    observaciones TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_abonos_cli_cliente FOREIGN KEY (cliente_id)
        REFERENCES clientes(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_abonos_cli_cuenta FOREIGN KEY (cuenta_bancaria_id)
        REFERENCES cuentas_bancarias(id) ON UPDATE CASCADE ON DELETE SET NULL,
    INDEX idx_abonos_clientes_fecha (fecha)
) ENGINE=InnoDB;

-- Abonos del negocio a la deuda total con cada proveedor
CREATE TABLE abonos_proveedores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    proveedor_id INT NOT NULL,
    fecha DATE NOT NULL,
    monto DECIMAL(12,2) NOT NULL,
    metodo_pago ENUM('efectivo', 'transferencia') NOT NULL,
    cuenta_bancaria_id INT,
    referencia VARCHAR(100),
    observaciones TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_abonos_prov_proveedor FOREIGN KEY (proveedor_id)
        REFERENCES proveedores(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_abonos_prov_cuenta FOREIGN KEY (cuenta_bancaria_id)
        REFERENCES cuentas_bancarias(id) ON UPDATE CASCADE ON DELETE SET NULL,
    INDEX idx_abonos_proveedores_fecha (fecha)
) ENGINE=InnoDB;

-- ============================================================================
-- 6. TABLAS DE DEVOLUCIONES
-- ============================================================================

-- Devoluciones de productos a proveedores
CREATE TABLE devoluciones_compra (
    id INT AUTO_INCREMENT PRIMARY KEY,
    proveedor_id INT NOT NULL,
    fecha DATE NOT NULL,
    motivo ENUM('insatisfaccion', 'defectuoso') NOT NULL,
    total DECIMAL(12,2) NOT NULL,
    observaciones TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_dev_compra_proveedor FOREIGN KEY (proveedor_id)
        REFERENCES proveedores(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_dev_compra_fecha (fecha)
) ENGINE=InnoDB;

-- Detalle de cada devolucion a proveedor
CREATE TABLE detalle_devoluciones_compra (
    id INT AUTO_INCREMENT PRIMARY KEY,
    devolucion_compra_id INT NOT NULL,
    compra_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(12,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_det_dev_compra_devolucion FOREIGN KEY (devolucion_compra_id)
        REFERENCES devoluciones_compra(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_det_dev_compra_compra FOREIGN KEY (compra_id)
        REFERENCES compras(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_det_dev_compra_producto FOREIGN KEY (producto_id)
        REFERENCES productos(id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Devoluciones de productos por parte de clientes
CREATE TABLE devoluciones_venta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    fecha DATE NOT NULL,
    motivo ENUM('insatisfaccion', 'defectuoso') NOT NULL,
    tipo_resolucion ENUM('descuento_deuda', 'devolucion_dinero') NOT NULL,
    total DECIMAL(12,2) NOT NULL,
    observaciones TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_dev_venta_cliente FOREIGN KEY (cliente_id)
        REFERENCES clientes(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_dev_venta_fecha (fecha)
) ENGINE=InnoDB;

-- Detalle de cada devolucion de cliente
CREATE TABLE detalle_devoluciones_venta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    devolucion_venta_id INT NOT NULL,
    venta_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(12,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_det_dev_venta_devolucion FOREIGN KEY (devolucion_venta_id)
        REFERENCES devoluciones_venta(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_det_dev_venta_venta FOREIGN KEY (venta_id)
        REFERENCES ventas(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_det_dev_venta_producto FOREIGN KEY (producto_id)
        REFERENCES productos(id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Devoluciones de servicio tecnico
CREATE TABLE devoluciones_servicio (
    id INT AUTO_INCREMENT PRIMARY KEY,
    orden_servicio_id INT NOT NULL,
    cliente_id INT NOT NULL,
    fecha DATE NOT NULL,
    motivo TEXT NOT NULL,
    tipo_resolucion ENUM('retrabajo', 'descuento_deuda', 'devolucion_dinero') NOT NULL,
    monto DECIMAL(12,2),
    nueva_orden_servicio_id INT,
    observaciones TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_dev_serv_orden FOREIGN KEY (orden_servicio_id)
        REFERENCES ordenes_servicio(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_dev_serv_cliente FOREIGN KEY (cliente_id)
        REFERENCES clientes(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_dev_serv_nueva_orden FOREIGN KEY (nueva_orden_servicio_id)
        REFERENCES ordenes_servicio(id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================================
-- 7. TABLA DE REEMBOLSOS (devolucion de dinero en efectivo o transferencia)
-- ============================================================================

-- Reembolsos por devoluciones de ventas de contado o servicios de contado
CREATE TABLE reembolsos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    devolucion_venta_id INT,
    devolucion_servicio_id INT,
    fecha DATE NOT NULL,
    monto DECIMAL(12,2) NOT NULL,
    metodo_pago ENUM('efectivo', 'transferencia') NOT NULL,
    cuenta_bancaria_id INT,
    referencia VARCHAR(100),
    observaciones TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reembolsos_dev_venta FOREIGN KEY (devolucion_venta_id)
        REFERENCES devoluciones_venta(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_reembolsos_dev_servicio FOREIGN KEY (devolucion_servicio_id)
        REFERENCES devoluciones_servicio(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_reembolsos_cuenta FOREIGN KEY (cuenta_bancaria_id)
        REFERENCES cuentas_bancarias(id) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_reembolso_origen CHECK (
        (devolucion_venta_id IS NOT NULL AND devolucion_servicio_id IS NULL)
        OR (devolucion_venta_id IS NULL AND devolucion_servicio_id IS NOT NULL)
    )
) ENGINE=InnoDB;

-- ============================================================================
-- 8. VISTAS PARA CALCULO DE DEUDAS
-- ============================================================================

-- Vista: Saldo (deuda) de cada cliente
-- Saldo positivo = el cliente debe dinero al negocio
-- Saldo negativo = el negocio tiene saldo a favor del cliente
CREATE OR REPLACE VIEW vista_saldo_clientes AS
SELECT
    c.id AS cliente_id,
    c.documento,
    c.nombre,
    c.telefono,
    COALESCE(vc.total_ventas_credito, 0) AS total_ventas_credito,
    COALESCE(sc.total_servicios_credito, 0) AS total_servicios_credito,
    COALESCE(ab.total_abonos, 0) AS total_abonos,
    COALESCE(dv.total_devoluciones_venta, 0) AS total_devoluciones_venta,
    COALESCE(ds.total_devoluciones_servicio, 0) AS total_devoluciones_servicio,
    (
        COALESCE(vc.total_ventas_credito, 0)
        + COALESCE(sc.total_servicios_credito, 0)
        - COALESCE(ab.total_abonos, 0)
        - COALESCE(dv.total_devoluciones_venta, 0)
        - COALESCE(ds.total_devoluciones_servicio, 0)
    ) AS saldo
FROM clientes c
LEFT JOIN (
    SELECT cliente_id, SUM(total) AS total_ventas_credito
    FROM ventas
    WHERE tipo_pago = 'credito'
    GROUP BY cliente_id
) vc ON c.id = vc.cliente_id
LEFT JOIN (
    SELECT cliente_id, SUM(precio_cliente) AS total_servicios_credito
    FROM ordenes_servicio
    WHERE tipo_pago = 'credito'
    GROUP BY cliente_id
) sc ON c.id = sc.cliente_id
LEFT JOIN (
    SELECT cliente_id, SUM(monto) AS total_abonos
    FROM abonos_clientes
    GROUP BY cliente_id
) ab ON c.id = ab.cliente_id
LEFT JOIN (
    SELECT cliente_id, SUM(total) AS total_devoluciones_venta
    FROM devoluciones_venta
    WHERE tipo_resolucion = 'descuento_deuda'
    GROUP BY cliente_id
) dv ON c.id = dv.cliente_id
LEFT JOIN (
    SELECT cliente_id, SUM(monto) AS total_devoluciones_servicio
    FROM devoluciones_servicio
    WHERE tipo_resolucion = 'descuento_deuda'
    GROUP BY cliente_id
) ds ON c.id = ds.cliente_id;

-- Vista: Saldo (deuda) con cada proveedor
-- Saldo positivo = el negocio debe dinero al proveedor
CREATE OR REPLACE VIEW vista_saldo_proveedores AS
SELECT
    p.id AS proveedor_id,
    p.nombre,
    p.nit,
    p.telefono,
    COALESCE(cc.total_compras_credito, 0) AS total_compras_credito,
    COALESCE(ab.total_abonos, 0) AS total_abonos,
    COALESCE(dc.total_devoluciones, 0) AS total_devoluciones,
    (
        COALESCE(cc.total_compras_credito, 0)
        - COALESCE(ab.total_abonos, 0)
        - COALESCE(dc.total_devoluciones, 0)
    ) AS saldo
FROM proveedores p
LEFT JOIN (
    SELECT proveedor_id, SUM(total) AS total_compras_credito
    FROM compras
    WHERE tipo_pago = 'credito'
    GROUP BY proveedor_id
) cc ON p.id = cc.proveedor_id
LEFT JOIN (
    SELECT proveedor_id, SUM(monto) AS total_abonos
    FROM abonos_proveedores
    GROUP BY proveedor_id
) ab ON p.id = ab.proveedor_id
LEFT JOIN (
    SELECT proveedor_id, SUM(total) AS total_devoluciones
    FROM devoluciones_compra
    GROUP BY proveedor_id
) dc ON p.id = dc.proveedor_id;

-- Vista: Rentabilidad por orden de servicio
CREATE OR REPLACE VIEW vista_rentabilidad_servicios AS
SELECT
    os.id AS orden_id,
    c.nombre AS cliente,
    cs.nombre AS centro_servicio,
    os.fecha_recepcion,
    os.estado,
    os.costo_servicio_centro,
    COALESCE(ins.total_costo_insumos, 0) AS total_costo_insumos,
    os.precio_cliente,
    (
        COALESCE(os.precio_cliente, 0)
        - COALESCE(os.costo_servicio_centro, 0)
        - COALESCE(ins.total_costo_insumos, 0)
    ) AS ganancia
FROM ordenes_servicio os
INNER JOIN clientes c ON os.cliente_id = c.id
INNER JOIN centros_servicio cs ON os.centro_servicio_id = cs.id
LEFT JOIN (
    SELECT orden_servicio_id, SUM(subtotal_costo) AS total_costo_insumos
    FROM insumos_orden_servicio
    GROUP BY orden_servicio_id
) ins ON os.id = ins.orden_servicio_id;
