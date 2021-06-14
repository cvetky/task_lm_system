sap.ui.jsview("webui.view.App", {

	getControllerName : function () {
		return "webui.controller.App";
	},

	createContent : function (oController) {
		// page
		var page1 = new sap.m.Page({
			title : "Task Executor v2.0"
		});

		// menu title
		var title = new sap.m.Title({
			text : "Tasks Overview",
			titleStyle : sap.ui.core.TitleLevel.H1,
			width : "100%",
			textAlign : sap.ui.core.TextAlign.Center
		});

		title.addStyleClass("sapUiMediumMarginTopBottom");
		page1.addContent(title);

		// menu buttons
		var dashboardButton = new sap.m.Button({
			text: "Dashboard",
			icon: "sap-icon://vertical-bar-chart",
			press: [oController.navigateToDashboard, oController]
		});

		var addTask = new sap.m.Button({
			text : "Add",
			icon : "sap-icon://add",
			press : [oController.showAddTaskDialog, oController]
		});

		var deleteAllTasks = new sap.m.Button({
			text : "Delete All",
			icon : "sap-icon://delete",
			press : [oController.showDeleteAllTasksDialog, oController]
		});

		var searchBar = new sap.m.SearchField({
			placeholder : "Search for a task",
			liveChange : [oController.onType, oController], // in handler "this" will be oController
			width : "20%"
		});

		var headerToolbar = new sap.m.Toolbar("headerT");

		headerToolbar.addContent(new sap.m.Title({
			text : "Tasks"
		}));
		headerToolbar.addContent(new sap.m.ToolbarSpacer());
		headerToolbar.addContent(dashboardButton);
		headerToolbar.addContent(addTask);
		headerToolbar.addContent(deleteAllTasks);
		headerToolbar.addContent(searchBar);

		// main content -> all tasks listed
		this.container = new sap.m.ListBase("container", {
			headerToolbar : headerToolbar,
			mode : sap.m.ListMode.Delete,
			noDataText : "No tasks were found.",
			delete : [oController.showDeleteTaskDialog, oController]
		});
		page1.addContent(this.container);

		this.container.bindAggregation("items", {
			path : "tasks>/",
			template : new sap.m.StandardListItem({
				type : sap.m.ListType.DetailAndActive,
				title : "{tasks>name}",
				description : "Template: {tasks>commandTemplate}",
				press : [oController.onTaskPressed, oController],
				detailPress : [oController.showUpdateTaskDialog, oController]
			})
		});

		// dialog for user input for adding new task
		this.addTaskDialog = new sap.m.Dialog({
			icon : "sap-icon://add-coursebook",
			title : "Input required data about the new task",
			contentWidth : "50%",
			beginButton : new sap.m.Button({
				icon : "sap-icon://accept",
				type : sap.m.ButtonType.Accept,
				press : [oController.addNewTask, oController]
			}),
			endButton : new sap.m.Button({
				icon : "sap-icon://decline",
				type : sap.m.ButtonType.Reject,
				press : [oController.closeAddTaskDialog, oController]
			}),
			afterClose : [oController.clearParams, oController]
		});

		this.inputForm = new sap.ui.layout.form.Form({
			layout : new sap.ui.layout.form.ResponsiveGridLayout({
				labelSpanM : 3
			}),
			title : "Input data"
		});

		this.updateTaskDialog = new sap.m.Dialog({
			icon : "sap-icon://user-edit",
			subHeader : new sap.m.Toolbar({
				content : new sap.m.Text({
					text : "Type a dash (-) for not updating a property. Note that you have to add parameters if the command template contains placeholders for parameter values!",
					textAlign : sap.ui.core.TextAlign.Center
				})
			}),
			contentWidth : "50%",
			beginButton : new sap.m.Button({
				icon : "sap-icon://accept",
				type : sap.m.ButtonType.Accept,
				press : [oController.updateTask, oController]
			}),
			endButton : new sap.m.Button({
				icon : "sap-icon://decline",
				type : sap.m.ButtonType.Reject,
				press : [oController.closeUpdateTaskDialog, oController]
			}),
			afterClose : [oController.clearParams, oController]
		});

		var taskInfoForm = new sap.ui.layout.form.Form({
			title : "Selected task info",
			layout : new sap.ui.layout.form.ResponsiveGridLayout({
				labelSpanM : 2
			}),
			formContainers : new sap.ui.layout.form.FormContainer({
				formElements : [
					new sap.ui.layout.form.FormElement({
						label : new sap.m.Label({
							text : "Name",
							wrapping : true
						}),
						fields : new sap.m.Text({
							text : "{selectedTask>/name}"
						})
					}),
					new sap.ui.layout.form.FormElement({
						label : new sap.m.Label({
							text : "Command template",
							wrapping : true
						}),
						fields : new sap.m.Text({
							text : "{selectedTask>/commandTemplate}"
						})
					}),
					new sap.ui.layout.form.FormElement({
						label : new sap.m.Label({
							text : "Time out period",
							wrapping : true
						}),
						fields : new sap.m.Text({
							text : "{selectedTask>/timeOut} seconds"
						})
					})
				]
			})
		});
		this.updateTaskDialog.addContent(taskInfoForm);
		var paramsForm = new sap.ui.layout.form.Form({
			layout : new sap.ui.layout.form.ResponsiveGridLayout({
				labelSpanM : 2
			})
		});
		paramsForm.bindAggregation("formContainers", {
			path : "selectedTask>/parameters",
			template : new sap.ui.layout.form.FormContainer({
				title : "Parameter",
				formElements : [
					new sap.ui.layout.form.FormElement({
						label : new sap.m.Label({
							text : "Name",
							wrapping : true
						}),
						fields : new sap.m.Text({
							text : "{selectedTask>name}"
						})
					}),
					new sap.ui.layout.form.FormElement({
						label : new sap.m.Label({
							text : "Type",
							wrapping : true
						}),
						fields : new sap.m.Text({
							text : "{selectedTask>typeDescription}"
						})
					}),
					new sap.ui.layout.form.FormElement({
						label : new sap.m.Label({
							text : "Hidden",
							wrapping : true
						}),
						fields : new sap.m.Text({
							text : "{selectedTask>hidden}"
						})
					})
				]
			})
		});
		this.updateTaskDialog.addContent(paramsForm);
		var envsForm = new sap.ui.layout.form.Form({
			layout : new sap.ui.layout.form.ResponsiveGridLayout({
				labelSpanM : 2
			}),
			formContainers : new sap.ui.layout.form.FormContainer({
				title : {
					path : "selectedTask>/environmentVariables",
					formatter : oController.checkForEmptyEnvs
				}
			}).bindAggregation("formElements", {
				path : "selectedTask>/environmentVariables",
				template : new sap.ui.layout.form.FormElement({
					label : new sap.m.Label({
							text : "Name",
							wrapping : true
						}),
					fields : new sap.m.Text({
						text : "{selectedTask>}"
					})
				})
			})
		});
		this.updateTaskDialog.addContent(envsForm);

		return page1;
	},

	addFormContainer : function() {
		var oController = this.getController();
		var formContainer = new sap.ui.layout.form.FormContainer();
		formContainer.addFormElement(new sap.ui.layout.form.FormElement({
			label : new sap.m.Label({
				required : true,
				text : "Task name",
				wrapping : true
			}),
			fields : new sap.m.Input({
				value : {
					path : "task>/name",
					mode : sap.ui.model.BindingMode.TwoWay
				},
				placeholder : "Name of the task",
				valueStateText : "Task name cannot contain spaces!",
				change : [oController.validateSpaces, oController]
			})
		}));
		formContainer.addFormElement(new sap.ui.layout.form.FormElement({
			label : new sap.m.Label({
				required : true,
				text : "Command template",
				wrapping : true
			}),
			fields : new sap.m.Input({
				value : {
					path : "task>/commandTemplate",
					mode : sap.ui.model.BindingMode.TwoWay
				},
				placeholder : "Template of the executable task",
				valueStateText : "Invalid placeholder(s) for parameter values!",
				change : [oController.validateTemplate, oController]
			})
		}));
		formContainer.addFormElement(new sap.ui.layout.form.FormElement({
			label : new sap.m.Label({
				text : "List of required environment variables",
				wrapping : true,
				textAlign : sap.ui.core.TextAlign.Left
			}),
			fields : new sap.m.TextArea({
				rows : 5,
				value : {
					path : "task>/environmentVariables",
					mode : sap.ui.model.BindingMode.TwoWay
				},
				placeholder : "Every environment variable name must be on a new line!",
				valueStateText : "Environment variable names can contain only letters, digits and underscores!",
				change : [oController.validateEnvironmentVariables, oController]
			})
		}));
		formContainer.addFormElement(new sap.ui.layout.form.FormElement({
			label : new sap.m.Label({
				required : true,
				text : "Time out period (in seconds)",
				wrapping : true
			}),
			fields : new sap.m.Input({
				value : {
					path : "task>/timeOut",
					mode : sap.ui.model.BindingMode.TwoWay
				},
				placeholder : "The task will be killed after this period!",
				valueStateText : "Time out period must be a number!",
				change : [oController.validateNumber, oController]

			})
		}));
		formContainer.addFormElement(new sap.ui.layout.form.FormElement({
			label : new sap.m.Label({
				text : "Add a parameter",
				wrapping : true
			}),
			fields : new sap.m.Button({
				icon : "sap-icon://add",
				width : "7%",
				type : sap.m.ButtonType.Emphasized,
				press : [oController.addParameter, oController]
			})
		}));
		this.inputForm.addFormContainer(formContainer);
	},

	addParameter : function(paramIndex) {
		var oController = this.getController();
		var paramNumber = this.inputForm.getFormContainers().length;
			this.inputForm.addFormContainer(new sap.ui.layout.form.FormContainer({
				title : "Parameter "+paramNumber+" info",
				formElements : [
					new sap.ui.layout.form.FormElement({
						label : new sap.m.Label({
							required : true,
							text : "Name",
							wrapping : true
						}),
						fields : new sap.m.Input({
							value : {
								path : "task>/parameters/"+paramIndex+"/name",
								mode : sap.ui.model.BindingMode.TwoWay
							},
							placeholder : "Name of the parameter",
							valueStateText : "Parameter name cannot contain spaces!",
							change : [oController.validateSpaces, oController]
						})
					}),
					new sap.ui.layout.form.FormElement({
						label : new sap.m.Label({
							required : true,
							text : "Type (s, i, r or b)",
							wrapping : true
						}),
						fields : new sap.m.Input({
							value : {
								path : "task>/parameters/"+paramIndex+"/type",
								mode : sap.ui.model.BindingMode.TwoWay
							},
							placeholder : "Type of the parameter",
							valueStateText : "Parameter type must be only one symbol from the specified in the brackets!",
							change : [oController.validateParamType, oController]
						})
					}),
					new sap.ui.layout.form.FormElement({
						label : new sap.m.Label({
							required : true,
							text : "Type description",
							wrapping : true
						}),
						fields : new sap.m.Input({
							value : {
								path : "task>/parameters/"+paramIndex+"/typeDescription",
								mode : sap.ui.model.BindingMode.TwoWay
							},
							placeholder : "Full name of the specified type",
							valueStateText : "Type description cannot contain spaces!",
							change : [oController.validateSpaces, oController]
						})
					}),
					new sap.ui.layout.form.FormElement({
						label : new sap.m.Label({
							required : true,
							text : "Hidden (true or false)",
							wrapping : true
						}),
						fields : new sap.m.Input({
							value : {
								path : "task>/parameters/"+paramIndex+"/hidden",
								mode : sap.ui.model.BindingMode.TwoWay
							},
							placeholder : "Determines if parameter value is readable or not.",
							valueStateText : "Hidden property can only be true or false!",
							change : [oController.validateBoolean, oController]
						})
					})
				]
		}));
	}
});