sap.ui.jsview("webui.view.CollectData", {

	getControllerName : function () {
		return "webui.controller.CollectData";
	},

	createContent : function (oController) {
		var that = this;

		// page
		var page1 = new sap.m.Page({
			title : "Task Executor v2.0",
			showNavButton : true,
			navButtonPress : [oController.back, oController]
		});
		
		var title = new sap.m.Title({
			text : "Selected task: {taskToExecute>/name}",
			titleStyle : sap.ui.core.TitleLevel.H1,
			width : "100%",
			textAlign : sap.ui.core.TextAlign.Center
		});

		title.addStyleClass("sapUiMediumMarginTopBottom");
		page1.addContent(title);

		var horizontalContainer = new sap.m.HBox({
			justifyContent : sap.m.FlexJustifyContent.Center
		});

		this.dataContainer = new sap.m.VBox({
			width : "60%"
		});

		var taskInfoForm = new sap.ui.layout.form.Form({
			toolbar : new sap.m.Toolbar({
				content : [
					new sap.m.Title({
						text : "Task info"
					}),
					new sap.m.ToolbarSpacer(),
					new sap.m.Button({
						text : "Proceed to execution",
						icon : "sap-icon://begin",
						press : [oController.toExecutionPage, oController]
					})
				]
			}),
			layout : new sap.ui.layout.form.ResponsiveGridLayout({
				labelSpanM : 3
			}),
			formContainers : new sap.ui.layout.form.FormContainer({
				formElements : [
					new sap.ui.layout.form.FormElement({
						label : new sap.m.Label({
							text : "Name",
							wrapping : true
						}),
						fields : new sap.m.Text({
							text : "{taskToExecute>/name}"
						})
					}),
					new sap.ui.layout.form.FormElement({
						label : new sap.m.Label({
							text : "Command template",
							wrapping : true
						}),
						fields : new sap.m.Text({
							text : "{taskToExecute>/commandTemplate}"
						})
					}),
					new sap.ui.layout.form.FormElement({
						label : new sap.m.Label({
							text : "Time out period",
							wrapping : true
						}),
						fields : new sap.m.Text({
							text : "{taskToExecute>/timeOut} seconds"
						})
					})
				]
			})
		});
		this.dataContainer.addItem(taskInfoForm);

		var paramsForm = new sap.ui.layout.form.Form({
			layout : new sap.ui.layout.form.ResponsiveGridLayout({
				labelSpanM : 3
			}),
			formContainers : new sap.ui.layout.form.FormContainer({
				title : "Parameters"
			}).bindAggregation("formElements", {
				path : "taskToExecute>/parameters",
				template : new sap.ui.layout.form.FormElement({
					label : new sap.m.Label({
						text : "{taskToExecute>name}",
						wrapping : true
					}),
					fields : new sap.m.Input({
						value : {
							path : "taskToExecute>value",
							mode : sap.ui.model.BindingMode.TwoWay
						},
						placeholder : "Input parameter value",
						type : {
							path : "taskToExecute>hidden",
							formatter : oController.setInputType
						},
						width : "60%"
					})
				})
			})
		});
		this.dataContainer.addItem(paramsForm);

		this.envsForm = new sap.ui.layout.form.Form({
			layout : new sap.ui.layout.form.ResponsiveGridLayout({
				labelSpanM : 3
			}),
			formContainers : new sap.ui.layout.form.FormContainer({
				title : {
					path : "taskToExecute>/environmentVariables",
					formatter : oController.checkForEmptyEnvs
				}
			}).bindAggregation("formElements", {
				path : "taskToExecute>/environmentVariables",
				template : new sap.ui.layout.form.FormElement({
					label : new sap.m.Label({
							text : "{taskToExecute>name}",
							wrapping : true
						}),
					fields : new sap.m.Input({
						value : {
							path : "taskToExecute>value",
							mode : sap.ui.model.BindingMode.TwoWay
						},
						placeholder : "Input environment variable value",
						width : "60%"
					})
				})
			})
		});
		
		this.dataContainer.addItem(this.envsForm);

		horizontalContainer.addItem(this.dataContainer);
		page1.addContent(horizontalContainer);

		return page1;
	}
});