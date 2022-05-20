# Databricks notebook source
from  MountSiloBlob import MountSiloBlob
from getSiloJDBC
jdbc_url = ConnectCDR(spark,'CS').get_jdbc()
#Print availible methods since databricks does not display them.
method_list = [method for method in dir(MountSiloBlob) if method.startswith('__') is False]
print(method_list)

# COMMAND ----------


mounter = MountSiloBlob(spark, 'CS')
bronzePath = mounter.mount_bronze()
clientDataPath = mounter.mount_clientdata()


# COMMAND ----------

mounter.walk_directory(bronzePath)

# COMMAND ----------

print(clientDataPath)
mounter.list_directory(clientDataPath)