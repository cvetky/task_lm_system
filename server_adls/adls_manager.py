import sys
from time import time
from azure.datalake.store import core
from azure.datalake.store import lib
from azure.datalake.store.multithread import ADLUploader


class AdlsManager(object):

    def __init__(self):
        self.__tenant_id = "bb9bc891-a81c-4296-bd5d-15aedd92502c"
        self.__client_id = "d1b5de72-67ad-49ef-ab10-b76d2ca70be7"
        self.__client_secret = "hoCO_19xn8frF~ivX81ioD.Yr5O9Pv9A-g"
        self.__resource = "https://datalake.azure.net/"
        self.__store_name = "cvetky"
        self.__adls_root_dir = "task_lm_system_data"

    def upload_file(self, name_prefix, content, extension):
        adl = self.__connect_to_adls()

        current_timestamp = time()
        adls_filepath = "/{dir}/{name}_{time}.{ext}".format(
            dir=self.__adls_root_dir, name=name_prefix,
            time=current_timestamp, ext=extension)

        with adl.open(adls_filepath, "wb") as f:
            f.write(bytes(content, encoding="utf8"))

    def __connect_to_adls(self):
        token = lib.auth(tenant_id=self.__tenant_id,
                         client_id=self.__client_id,
                         client_secret=self.__client_secret,
                         resource=self.__resource)
        return core.AzureDLFileSystem(token, store_name=self.__store_name)
