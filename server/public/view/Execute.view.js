sap.ui.jsview("webui.view.Execute", {

	getControllerName : function () {
		return "webui.controller.Execute";
	},

	createContent : function (oController) {
		var that = this;

		// page
		var page1 = new sap.m.Page({
			title : "Task Executor v2.0",
			footer : new sap.m.Toolbar({
				content : [
					new sap.m.Title({
						text : "Execution control"
					}),
					new sap.m.ToolbarSpacer(),
					new sap.m.Button({
						text : "Pause",
						icon : "sap-icon://pause",
						press : [oController.pauseTask, oController]
					}),
					new sap.m.Button({
						text : "Resume",
						icon : "sap-icon://play",
						press : [oController.resumeTask, oController]
					}),
					new sap.m.Button({
						text : "Stop",
						icon : "sap-icon://stop",
						press : [oController.stopTask, oController]
					})
				]
			})
		});
		
		var title = new sap.m.Title({
			text : "Execution of task {taskToMonitor>/name}",
			titleStyle : sap.ui.core.TitleLevel.H1,
			width : "100%",
			textAlign : sap.ui.core.TextAlign.Center
		});

		title.addStyleClass("sapUiMediumMarginTopBottom");
		page1.addContent(title);

		var horizontalContainer = new sap.m.HBox({
			justifyContent : sap.m.FlexJustifyContent.Center
		});

		var dataContainer = new sap.m.VBox({
			width : "75%",
		});

		this.outputArea = new sap.m.TextArea("outputArea", {
			editable : false,
			height : (window.innerHeight-300)+"px",
			value : ""
		});
		var that = this;
		// attach resize event for the textArea
		$(window).resize(function(event) {
			that.outputArea.setHeight(($(this).height()-300)+"px");
		});

		this.dashboardButton = new sap.m.Button({
			text: "Dashboard",
			icon: "sap-icon://vertical-bar-chart",
			press: [oController.navigateToDashboard, oController],
			visible: false
		});
		this.mainPageButton = new sap.m.Button({
			text : "Back to main page",
			icon : "sap-icon://home",
			press : [oController.toMainPage, oController],
			visible : false
		});
		this.executeButton = new sap.m.Button({
			text : "Start execution",
			icon : "sap-icon://begin",
			press : [oController.executeTask, oController]
		});

		var taskOutputForm = new sap.ui.layout.form.Form({
			toolbar : new sap.m.Toolbar({
				content : [
					new sap.m.Title({
						text : "Task output"
					}),
					new sap.m.ToolbarSpacer(),
					this.dashboardButton,
					this.mainPageButton,
					this.executeButton
				]
			}),
			layout : new sap.ui.layout.form.ResponsiveGridLayout({
				labelSpanM : 2
			}),
			formContainers : new sap.ui.layout.form.FormContainer({
				formElements : new sap.ui.layout.form.FormElement({
					fields : this.outputArea
				})
			})
		});
		dataContainer.addItem(taskOutputForm);

		horizontalContainer.addItem(dataContainer);
		page1.addContent(horizontalContainer);

		return page1;
	}
});