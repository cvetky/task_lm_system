sap.ui.define([
	"sap/ui/core/mvc/Controller"
], function(Controller) {
	"use strict";
	jQuery.sap.require("sap.m.MessageBox");
	jQuery.sap.require("sap.ui.commons.MessageBox")

	return Controller.extend("webui.controller.Execute", {

		navigateToDashboard : function() {
			var dashboardUrl = "https://sap-validation.eu10.sapanalytics.cloud/sap/fpa/ui/tenants/f31b1/bo/story/BA9343001423F190AA1523DF999C6C39";
			sap.ui.require([
				"sap/m/library"
			], sapMLib => sapMLib.URLHelper.redirect(dashboardUrl, true));
		},

		toMainPage : function(oControlEvent) {
			oControlEvent.getSource().setVisible(false);
			this.getView().dashboardButton.setVisible(false);
			this.getView().executeButton.setEnabled(true);
			this.getView().outputArea.setValue("");
			var indexPage = sap.ui.getCore().byId("indexPage");
			indexPage.getController().onInit(); // to update tasks list
			sap.ui.getCore().byId("app").to(indexPage);
		},

		executeTask : function(oControlEvent) {
			oControlEvent.getSource().setEnabled(false);
			var that = this;

			jQuery.ajax({
				type : "GET",
				contentType : "application/json",
				url : window.origin+"/isTaskRunning",
				dataType : "json",
				success : function(data, textStatus, jqXHR) {
					sap.m.MessageBox.information("A task is already running! You will be attached to it!");
					var obj = {
						name : data.name
					};
					var model = new sap.ui.model.json.JSONModel();
					model.setData(obj); 
					that.getView().setModel(model, "taskToMonitor");
					that.monitorTask(0);
				},
				error : function(jqXHR, textStatus, errorThrown) {
					if(jqXHR.status != 400) {
						sap.m.MessageBox.error(textStatus);
					}
					var oData = that.getView().getModel("taskToMonitor").getData();
					var parametersValues = [];
					for(var i=0; i<oData.parameters.length; i++) {
						parametersValues.push(oData.parameters[i].value);
					}
					var envsValues = [];
					for(var i=0; i<oData.environmentVariables.length; i++) {
						envsValues.push(oData.environmentVariables[i].value);
					}
					var execObject = {
						paramValues : parametersValues,
						varsValues : envsValues
					};
					jQuery.ajax({
						type : "POST",
						url : window.origin+"/exec/"+oData.name,
						dataType : "json",
						contentType : "application/json; charset=utf8",
						data : JSON.stringify(execObject),
						success : function(data, textStatus, jqXHR) {
							that.status = "running";
							that.monitorTask(0);
						},
						error : function(jqXHR, textStatus, errorThrown) {
							if(jqXHR.responseJSON.error) {
								sap.m.MessageBox.error(jqXHR.responseJSON.error);
							} else {
								sap.m.MessageBox.error(errorThrown);
							}
						}
					});
				}
			});
		},

		monitorTask : function(startLine) {
			var that = this;
			var dashboardButton = this.getView().dashboardButton;
			var mainPageButton = this.getView().mainPageButton;
			var outputArea = this.getView().outputArea;
			jQuery.ajax({
				type : "GET",
				contentType : "application/json",
				url : window.origin+"/outputLines/"+startLine,
				dataType : "json",
				success : function(data, textStatus, jqXHR) {
					var currentOutput = "";
					for(var i=0; i<data.lines.length; i++) {
						startLine++;
						currentOutput += data.lines[i];
					}
					outputArea.setValue(outputArea.getValue()+currentOutput);
					if(data.finished) {
						return;
					}
					setTimeout(function() {
						that.monitorTask(startLine);
					}, 1000);
				},
				error : function(jqXHR, textStatus, errorThrown) {
					if(jqXHR.status != 400) {
						sap.m.MessageBox.error(textStatus);
					}
					that.status = "killed";	
					dashboardButton.setVisible(true);
					mainPageButton.setVisible(true);
				}
			});
		},

		pauseTask : function() {
			var that = this;
			if(this.status && (this.status !== "paused" && this.status !== "killed")) {
				jQuery.ajax({
					type : "POST",
					url : window.origin+"/pause",
					dataType : "json",
					contentType : "application/json; charset=utf8",
					success : function(data, textStatus, jqXHR) {
						that.status = data.status;
					},
					error : function(jqXHR, textStatus, errorThrown) {
						if(jqXHR.status != 400) {
							sap.m.MessageBox.error(textStatus);
						}
					}
				});
			}
		},

		resumeTask : function() {
			var that = this;
			if(this.status && this.status === "paused") {
				jQuery.ajax({
					type : "POST",
					url : window.origin+"/resume",
					dataType : "json",
					contentType : "application/json; charset=utf8",
					success : function(data, textStatus, jqXHR) {
						that.status = data.status;
					},
					error : function(jqXHR, textStatus, errorThrown) {
						if(jqXHR.status != 400) {
							sap.m.MessageBox.error(textStatus);
						}
					}
				});
			}
		},

		stopTask : function() {
			var that = this;
			if(this.status && this.status !== "killed") {
				jQuery.ajax({
					type : "POST",
					url : window.origin+"/kill",
					dataType : "json",
					contentType : "application/json; charset=utf8",
					success : function(data, textStatus, jqXHR) {
						that.status = data.status;
					},
					error : function(jqXHR, textStatus, errorThrown) {
						if(jqXHR.status != 400) {
							sap.m.MessageBox.error(textStatus);
						}
					}
				});
			}
		},

		status : "unknown"
	});
});