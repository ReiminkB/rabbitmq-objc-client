import XCTest

class ConnectionTuningTest: XCTestCase {
    func testUsesClientTuneOptionsWhenServersAreZeroes() {
        let transport = ControlledInteractionTransport()
        connectWithOptions(transport, 12, 10, 9)
        XCTAssertEqual(
            clientTuneOk(
                AMQShort(12), AMQLong(10), AMQShort(9)
            ),
            negotiatedParamsGivenServerParams(
                transport,
                 AMQShort(0),  AMQLong(0), AMQShort(0)
            )
        )
    }

    func testUsesServerTuneOptionsWhenClientsAreZeroes() {
        let transport = ControlledInteractionTransport()
        connectWithOptions(transport, 0, 0, 0)
        XCTAssertEqual(
            clientTuneOk(
                AMQShort(12), AMQLong(10), AMQShort(9)
            ),
            negotiatedParamsGivenServerParams(
                transport,
                AMQShort(12), AMQLong(10), AMQShort(9)
            )
        )
    }

    func testUsesClientTuneOptionsWhenServersAreHigher() {
        let transport = ControlledInteractionTransport()
        connectWithOptions(transport, 11, 9, 8)
        XCTAssertEqual(
            clientTuneOk(
                AMQShort(11),  AMQLong(9), AMQShort(8)
            ),
            negotiatedParamsGivenServerParams(
                transport,
                AMQShort(12), AMQLong(10), AMQShort(9)
            )
        )
    }

    func testUsesServerTuneOptionsWhenClientsAreHigher() {
        let transport = ControlledInteractionTransport()
        connectWithOptions(transport, 12, 11, 10)
        XCTAssertEqual(
            clientTuneOk(
                AMQShort(11), AMQLong(10), AMQShort(9)
            ),
            negotiatedParamsGivenServerParams(
                transport,
                AMQShort(11), AMQLong(10), AMQShort(9)
            )
        )
    }

    // MARK: Helpers

    func connectWithOptions(transport: ControlledInteractionTransport, _ channelMax: Int, _ frameMax: Int, _ heartbeat: Int) -> RMQConnection {
        let connection = RMQConnection(
            transport: transport,
            user: "foo",
            password: "bar",
            vhost: "baz",
            channelMax: channelMax,
            frameMax: frameMax,
            heartbeat: heartbeat,
            syncTimeout: 0,
            delegate: nil
        )
        connection.start()
        transport.serverSendsPayload(MethodFixtures.connectionStart(), channelNumber: 0)
        return connection
    }

    func clientTuneOk(channelMax: AMQShort, _ frameMax: AMQLong, _ heartbeat: AMQShort) -> AMQConnectionTuneOk {
        return AMQConnectionTuneOk(channelMax: channelMax, frameMax: frameMax, heartbeat: heartbeat)
    }

    func negotiatedParamsGivenServerParams(transport: ControlledInteractionTransport, _ channelMax: AMQShort, _ frameMax: AMQLong, _ heartbeat: AMQShort) -> AMQConnectionTuneOk {
        let tune = AMQConnectionTune(channelMax: channelMax, frameMax: frameMax, heartbeat: heartbeat)

        transport
            .serverSendsPayload(MethodFixtures.connectionStart(), channelNumber: 0)
            .serverSendsPayload(tune, channelNumber: 0)

        let parser = AMQParser(data: transport.outboundData[transport.outboundData.count - 2])
        let frame = AMQFrame(parser: parser)
        return frame.payload as! AMQConnectionTuneOk
    }
}
