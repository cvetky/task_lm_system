sap.ui.define([
	"sap/ui/core/mvc/Controller"
], function(Controller) {
	"use strict";
	jQuery.sap.require("sap.m.MessageBox");
	jQuery.sap.require("sap.ui.commons.MessageBox");

	return Controller.extend("webui.controller.CollectData", {

		back : function() {
			sap.ui.getCore().byId("indexPage").getController().onInit(); // to update tasks list
			sap.ui.getCore().byId("app").back();
		},

		setInputType : function(hidden) {
			if(hidden === "true") {
				return sap.m.InputType.Password;
			} else {
				return sap.m.InputType.Text;
			}
		},

		checkForEmptyEnvs : function(envs) {
			if(envs.length === 0) {
				return "The task does not require environment variables!";
			} else {
				return "Environment variables";
			}
		},

		toExecutionPage : function() {
			var that = this;
			var oModel = this.getView().getModel("taskToExecute");
			var params = oModel.getData().parameters;
			var objects = [];

			for(var i=0; i<params.length; i++) {
				var obj = {
					type : params[i].type,
					value : params[i].value
				};
				objects.push(obj);
			}
			jQuery.ajax({
				type : "POST",
				url : window.origin+"/params",
				dataType : "json",
				contentType : "application/json; charset=utf8",
				data : JSON.stringify(objects),
				async : false,
				success : function() {
					var executePage = sap.ui.getCore().byId("executePage");
					executePage.setModel(oModel, "taskToMonitor");
					sap.ui.getCore().byId("app").to(executePage);
				},
				error : function(jqXHR, textStatus, errorThrown) {
					if(jqXHR.status == 400) {
						sap.m.MessageBox.error("Parameters' values cannot be empty and must be of the required type!");
					} else {
						sap.m.MessageBox.error(errorThrown);
					}
				}
			});
		}
	});
});