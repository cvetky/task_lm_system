sap.ui.define([
	"sap/ui/core/mvc/Controller"
], function(Controller) {
	"use strict";
	jQuery.sap.require("sap.m.MessageBox");
	jQuery.sap.require("sap.ui.commons.MessageBox");

	return Controller.extend("webui.controller.App", {
		onInit : function() {

			jQuery.ajax({
				type : "GET",
				contentType : "application/json",
				url : window.origin+"/isTaskRunning",
				dataType : "json",
				success : function(data, textStatus, jqXHR) {
					var executePage = sap.ui.getCore().byId("executePage");
					var controller = executePage.getController();
					var obj = {
						name : data.name
					};
					var model = new sap.ui.model.json.JSONModel();
					model.setData(obj); 
					executePage.setModel(model, "taskToMonitor");
					sap.ui.getCore().byId("app").to(executePage);
					controller.monitorTask(0);
				},
				error : function(jqXHR, textStatus, errorThrown) {
					if(jqXHR.status != 400) {
						sap.m.MessageBox.error(textStatus);
					}
				}
			});

			var oModel = new sap.ui.model.json.JSONModel();
			jQuery.ajax({
				type : "GET",
				contentType : "application/json",
				url : window.origin+"/tasks",
				dataType : "json",
				success : function(data, textStatus, jqXHR) {
					oModel.setData(data);
				},
				error : function(jqXHR, textStatus, errorThrown) {
					if(jqXHR.responseJSON.error) {
						sap.m.MessageBox.error(jqXHR.responseJSON.error);
					} else {
						sap.m.MessageBox.error(errorThrown);
					}
				}
			});
			this.getView().setModel(oModel, "tasks");
		},

		onType : function(oControlEvent) {
			var aFilter = [];
			var searchText = oControlEvent.getParameters().newValue;
			aFilter.push(new sap.ui.model.Filter("name", sap.ui.model.FilterOperator.Contains, searchText));
			// filter binding
			var oBinding = this.getView().container.getBinding("items");
			oBinding.filter(aFilter);
		},

		showAddTaskDialog : function() {
			this.paramIndex = -1;
			this.invalids = 0;
			var addTaskDialog = this.getView().addTaskDialog;
			var inputForm = this.getView().inputForm;
			var oModel = new sap.ui.model.json.JSONModel();

			inputForm.setModel(oModel, "task");
			addTaskDialog.addContent(inputForm);
			this.getView().addFormContainer();
			addTaskDialog.open();
		},

		closeAddTaskDialog : function() {
			this.getView().addTaskDialog.close();
		},

		clearParams : function() {
			this.getView().inputForm.removeAllFormContainers();
		},

		addParameter : function() {
			this.paramIndex++;
			var inputForm = this.getView().inputForm;
			var oModel = inputForm.getModel("task");
			var oData = oModel.getData();
			if(oData.parameters) {
				oData.parameters.push({}); // adding empty parameter to the model
			} else {
				oData.parameters = [{}]; // adding the first empty param
			}
			inputForm.setModel(oData, "tasks");

			var inputForm = this.getView().addParameter(this.paramIndex);
		},

		navigateToDashboard : function() {
			var dashboardUrl = "https://sap-validation.eu10.sapanalytics.cloud/sap/fpa/ui/tenants/f31b1/bo/story/BA9343001423F190AA1523DF999C6C39";
			sap.ui.require([
				"sap/m/library"
			], sapMLib => sapMLib.URLHelper.redirect(dashboardUrl, true));
		},

		addNewTask : function() {
			if(this.invalids > 0) {
				return;
			}
			var that = this;
			var inputForm = this.getView().inputForm;
			var oModel = inputForm.getModel("task");

			var taskName = oModel.getProperty("/name");
			var template = oModel.getProperty("/commandTemplate");
			var envString = oModel.getProperty("/environmentVariables");
			var envArray = envString ? envString.split("\n") : [];
			var timeOutPeriod = oModel.getProperty("/timeOut");
			var params = oModel.getProperty("/parameters");
			
			var taskObject = {
				name : taskName,
				commandTemplate : template,
				parameters : params,
				environmentVariables : envArray,
				timeOut : timeOutPeriod
			};

			var aData = jQuery.ajax({
				type : "POST",
				url : window.origin+"/tasks",
				dataType : "json",
				contentType : "application/json; charset=utf8",
				data : JSON.stringify(taskObject),
				success : function(data, textStatus, jqXHR) {
					sap.m.MessageToast.show(data.success);
					that.closeAddTaskDialog();
					that.onInit();
				},
				error : function(jqXHR, textStatus, errorThrown) {
					if(jqXHR.responseJSON.error) {
						sap.m.MessageBox.error(jqXHR.responseJSON.error);
					} else {
						sap.m.MessageBox.error(errorThrown);
					}
				}
			});
		},

		showDeleteAllTasksDialog : function() {
			var that = this;
			this.paramIndex = -1;
			sap.m.MessageBox.confirm("Confirm deleting all available tasks?", function(oAction) {
				if(oAction === sap.ui.commons.MessageBox.Action.OK) {
					that.deleteAllTasks();
				}
			});
		},

		deleteAllTasks : function() {
			var aData = jQuery.ajax({
				type : "DELETE",
				contentType : "application/json",
				url : window.origin+"/tasks",
				dataType : "json",
				success : function(data, textStatus, jqXHR) {
					sap.m.MessageToast.show(data.success);
				},
				error : function(jqXHR, textStatus, errorThrown) {
					if(jqXHR.responseJSON.error) {
						sap.m.MessageBox.error(jqXHR.responseJSON.error);
					} else {
						sap.m.MessageBox.error(errorThrown);
					}
				}
			});
			this.onInit();
		},

		showDeleteTaskDialog : function(oControlEvent) {
			var that = this;
			var taskItem = oControlEvent.getParameters().listItem;
			var path = taskItem.getBindingContextPath();
			var taskObject = this.getView().getModel("tasks").getObject(path);
			var taskName = taskObject.name;
			sap.m.MessageBox.confirm("Confirm deleting the task '"+taskName+"'?", function(oAction) {
				if(oAction === sap.ui.commons.MessageBox.Action.OK) {
					that.deleteTask(taskName);
				}
			});
		},

		deleteTask : function(name) {
			var aData = jQuery.ajax({
				type : "DELETE",
				contentType : "application/json",
				url : window.origin+"/tasks/"+name,
				dataType : "json",
				success : function(data, textStatus, jqXHR) {
					sap.m.MessageToast.show(data.success);
				},
				error : function(jqXHR, textStatus, errorThrown) {
					if(jqXHR.responseJSON.error) {
						sap.m.MessageBox.error(jqXHR.responseJSON.error);
					} else {
						sap.m.MessageBox.error(errorThrown);
					}
				}
			});
			this.onInit();
		},

		showUpdateTaskDialog : function(oControlEvent) {
			this.paramIndex = -1;
			this.invalids = 0;
			var that = this;

			var taskItem = oControlEvent.getSource();
			var path = taskItem.getBindingContextPath();
			var taskObject = this.getView().getModel("tasks").getObject(path);
			var oModel = new sap.ui.model.json.JSONModel();
			oModel.setData(taskObject);

			var updateTaskDialog = this.getView().updateTaskDialog;
			updateTaskDialog.setTitle("Input updated data about the task '"+taskObject.name+"'");

			updateTaskDialog.setModel(oModel, "selectedTask");

			var objectWithEmptyArrays = {
				parameters : [],
				environmentVariables : ""
			}
			var inputForm = this.getView().inputForm;
			var oModelInput = new sap.ui.model.json.JSONModel();
			oModelInput.setData(objectWithEmptyArrays);

			inputForm.setModel(oModelInput, "task");
			updateTaskDialog.addContent(inputForm);
			this.getView().addFormContainer();
			updateTaskDialog.open();
		},

		updateTask : function() {
			if(this.invalids > 0) {
				return;
			}
			var that = this;
			var inputForm = this.getView().inputForm;
			var updateTaskDialog = this.getView().updateTaskDialog;
			var oModel = inputForm.getModel("task");

			var taskName = oModel.getProperty("/name");
			var template = oModel.getProperty("/commandTemplate");
			var envString = oModel.getProperty("/environmentVariables");
			var envArray = envString ? envString.split("\n") : [];
			var timeOutPeriod = oModel.getProperty("/timeOut");
			var params = oModel.getProperty("/parameters");
			
			var taskObject = {
				name : taskName,
				commandTemplate : template,
				parameters : params,
				environmentVariables : envArray,
				timeOut : timeOutPeriod
			};

			var name = updateTaskDialog.getModel("selectedTask").getData().name;

			var aData = jQuery.ajax({
				type : "PUT",
				url : window.origin+"/tasks/"+name,
				dataType : "json",
				contentType : "application/json; charset=utf8",
				data : JSON.stringify(taskObject),
				success : function(data, textStatus, jqXHR) {
					sap.m.MessageToast.show(data.success);
					that.closeUpdateTaskDialog();
					that.onInit();
				},
				error : function(jqXHR, textStatus, errorThrown) {
					if(jqXHR.responseJSON.error) {
						sap.m.MessageBox.error(jqXHR.responseJSON.error);
					} else {
						sap.m.MessageBox.error(errorThrown);
					}
				}
			});	
		},

		closeUpdateTaskDialog : function() {
			this.getView().updateTaskDialog.close();
		},

		onTaskPressed : function(oControlEvent) {
			var taskItem = oControlEvent.getSource();
			var path = taskItem.getBindingContextPath();
			var taskObject = this.getView().getModel("tasks").getObject(path);
			
			// transforming environment variables to objects
			var envs = taskObject.environmentVariables;
			var envsNew = [];
			for(var i=0; i<envs.length; i++) {
				envsNew[i] = {
					name : envs[i]
				}
			}
			taskObject.environmentVariables = envsNew;

			var oModel = new sap.ui.model.json.JSONModel();
			oModel.setData(taskObject);
			var collectDataPage = sap.ui.getCore().byId("collectDataPage");
			collectDataPage.setModel(oModel, "taskToExecute");
			sap.ui.getCore().byId("app").to(collectDataPage);
		},

		validateSpaces : function(oControlEvent) {
			var inputField = oControlEvent.getSource();
			var value = oControlEvent.getParameters().value;
			if(value.match(/\s/)) {
				if(inputField.getValueState() != sap.ui.core.ValueState.Error) {
					inputField.setValueState(sap.ui.core.ValueState.Error);
					this.invalids++;
				}
			} else if(inputField.getValueState() != sap.ui.core.ValueState.None) {
				inputField.setValueState(sap.ui.core.ValueState.None);
				this.invalids--;
			}
		},

		validateTemplate : function(oControlEvent) {
			var inputField = oControlEvent.getSource();
			var value = oControlEvent.getParameters().value;
			var possiblyWrongValue = value.replace(/{\w+}/g, "");
			if(possiblyWrongValue.match(/{|}/)) {
				if(inputField.getValueState() != sap.ui.core.ValueState.Error) {
					inputField.setValueState(sap.ui.core.ValueState.Error);
					this.invalids++;
				}
			} else if(inputField.getValueState() != sap.ui.core.ValueState.None) {
				inputField.setValueState(sap.ui.core.ValueState.None);
				this.invalids--;
			}
		},

		validateEnvironmentVariables : function(oControlEvent) {
			var inputField = oControlEvent.getSource();
			var value = oControlEvent.getParameters().value;
			if(value.match(/[^-A-Za-z0-9_\n]/)) {
				if(inputField.getValueState() != sap.ui.core.ValueState.Error) {
					inputField.setValueState(sap.ui.core.ValueState.Error);
					this.invalids++;
				}
			} else if(inputField.getValueState() != sap.ui.core.ValueState.None) {
				inputField.setValueState(sap.ui.core.ValueState.None);
				this.invalids--;
			}
		},

		validateNumber : function(oControlEvent) {	
			var inputField = oControlEvent.getSource();
			var value = oControlEvent.getParameters().value;
			if(value.match(/[^0-9]/) && !value.match(/^-$/)) {
				if(inputField.getValueState() != sap.ui.core.ValueState.Error) {
					inputField.setValueState(sap.ui.core.ValueState.Error);
					this.invalids++;
				}
			} else if(inputField.getValueState() != sap.ui.core.ValueState.None) {
				inputField.setValueState(sap.ui.core.ValueState.None);
				this.invalids--;
			}
		},

		validateParamType : function(oControlEvent) {
			var inputField = oControlEvent.getSource();
			var value = oControlEvent.getParameters().value;
			if(!(value.match(/^(s|i|r|b){1}$/i)) && !value.match(/^-$/)) {
				if(inputField.getValueState() != sap.ui.core.ValueState.Error) {
					inputField.setValueState(sap.ui.core.ValueState.Error);
					this.invalids++;
				}
			} else if(inputField.getValueState() != sap.ui.core.ValueState.None) {
				inputField.setValueState(sap.ui.core.ValueState.None);
				this.invalids--;
			}
		},

		validateBoolean : function(oControlEvent) {
			var inputField = oControlEvent.getSource();
			var value = oControlEvent.getParameters().value;
			if(!(value.match(/^(true|false)$/i)) && !value.match(/^-$/)) {
				if(inputField.getValueState() != sap.ui.core.ValueState.Error) {
					inputField.setValueState(sap.ui.core.ValueState.Error);
					this.invalids++;
				}
			} else if(inputField.getValueState() != sap.ui.core.ValueState.None) {
				inputField.setValueState(sap.ui.core.ValueState.None);
				this.invalids--;
			}
		},

		checkForEmptyEnvs : function(envs) {
			console.log(envs);
			if(envs.length === 0) {
				return "The task does not require environment variables!";
			} else {
				return "Environment variables";
			}
		},

		invalids : 0,

		paramIndex : -1
	});
});