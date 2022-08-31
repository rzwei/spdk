from spdk.sma import DeviceManager
from spdk.sma.proto import sma_pb2


class TestCryptoEngine(CryptoEngine):
    def __init__(self):
        super().__init__('crypto-plugin2')

    def setup(self, volume_id, key, cipher, key_name, key2=None):
        pass

    def cleanup(self, volume_id):
        pass

    def verify(self, volume_id, key, cipher, key_name, key2=None):
        pass

    def get_crypto_bdev(self, volume_id):
        return volume_id


class TestDeviceManager1(DeviceManager):
    def __init__(self, client):
        super().__init__('plugin2-device1', 'nvme', client)

    def create_device(self, request):
        return sma_pb2.CreateDeviceResponse(handle=f'{self.protocol}:{self.name}')


class TestDeviceManager2(DeviceManager):
    def __init__(self, client):
        super().__init__('plugin2-device2', 'nvmf_tcp', client)

    def create_device(self, request):
        return sma_pb2.CreateDeviceResponse(handle=f'{self.protocol}:{self.name}')


devices = [TestDeviceManager1, TestDeviceManager2]
