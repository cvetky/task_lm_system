import json
from flask import Flask, Response, request
from adls_manager import AdlsManager

app = Flask(__name__)
app.config["DEBUG"] = True


@app.route("/adls_upload", methods=["POST"])
def upload_data_to_datalake():
    statistics_data = request.json
    statistics_data_str = json.dumps(statistics_data)

    file_name = "task_execution"
    extension = "json"
    am = AdlsManager()

    stat = 201
    message = "Statistics file successfully uploaded on the Data Lake."

    try:
        am.upload_file(file_name, statistics_data_str, extension)
    except Exception as e:
        stat = 400
        message = "Error during upload of statistics file to the Data Lake.\n"
        message += "The following exception occurred: {0}".format(str(e))

    respone_body = {
        "message": message
    }
    return Response(
        json.dumps(respone_body), status=stat, mimetype="application/json")


app.run()
