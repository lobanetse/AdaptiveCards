﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;

namespace AdaptiveCards.Rendering
{
    public static class ControlExtensions
    {
        public static object GetContext(this FrameworkElement element)
        {
            return element?.DataContext;
        }

        public static void SetContext(this FrameworkElement element, object value)
        {
            element.DataContext = value;
        }

        public static void SetState(this CheckBox control, bool value)
        {
            control.IsChecked = value;
        }

        public static bool? GetState(this CheckBox control)
        {
            return control.IsChecked;
        }

        public static void Add (this ListBox control, object element)
        {
            control.Items.Add(element);
        }
    }
}